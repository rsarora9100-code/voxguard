import uuid
from datetime import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.logging import logger
from app.db.models import CallRecord, AssistantDialogue
from app.services.scam_analyzer import scam_analyzer
from app.services.risk_engine import risk_engine

class AIAssistantDialogueManager:
    """
    Manages conversational AI call screening turns, multilingual prompts,
    and call termination or pass-through decisions.
    """

    GREETINGS = {
        "en": "Hello, I am the VoxGuard AI Voice Assistant. Who is calling and what is the reason for your call?",
        "es": "Hola, soy el asistente de voz VoxGuard AI. ¿Quién llama y cuál es el motivo de su llamada?",
        "hi": "नमस्ते, मैं वोक्सगार्ड एआई वॉयस असिस्टेंट हूँ। आप कौन बोल रहे हैं और आपके कॉल का क्या कारण है?",
        "fr": "Bonjour, je suis l'assistant vocal IA VoxGuard. Qui est à l'appareil et quel est l'objet de votre appel ?",
        "de": "Hallo, ich bin der VoxGuard KI-Sprachassistent. Wer ruft an und was ist der Grund Ihres Anrufs?"
    }

    def start_screening(
        self,
        db: Session,
        caller_number: str,
        caller_name: Optional[str] = "Unknown Caller",
        preferred_language: str = "en"
    ) -> Dict[str, Any]:
        """
        Initializes an AI screening session for an incoming call.
        """
        call_id = f"call-{uuid.uuid4().hex[:12]}"
        lang = preferred_language if preferred_language in self.GREETINGS else "en"
        initial_msg = self.GREETINGS[lang]

        # Initial risk assessment
        initial_eval = risk_engine.evaluate(db, caller_number, caller_name=caller_name)

        # Create CallRecord in DB
        call_rec = CallRecord(
            id=call_id,
            caller_number=caller_number,
            caller_name=initial_eval["caller_name"],
            call_type="screened",
            status="active",
            final_risk_score=initial_eval["final_score"],
            risk_level=initial_eval["risk_level"]
        )
        db.add(call_rec)

        # Log AI greeting
        dialogue = AssistantDialogue(
            call_id=call_id,
            speaker="assistant",
            text=initial_msg,
            language=lang,
            confidence=1.0
        )
        db.add(dialogue)
        db.commit()

        return {
            "call_id": call_id,
            "initial_assistant_message": initial_msg,
            "initial_risk_score": initial_eval["final_score"],
            "risk_level": initial_eval["risk_level"],
            "color_code": initial_eval["color_code"],
            "supported_languages": list(self.GREETINGS.keys())
        }

    def process_caller_turn(
        self,
        db: Session,
        call_id: str,
        caller_transcript: str,
        detected_language: str = "en",
        is_deepfake: bool = False,
        deepfake_confidence: float = 0.0
    ) -> Dict[str, Any]:
        """
        Processes caller's spoken response, updates dialogue history, evaluates risk,
        and generates the AI assistant's next response.
        """
        call_rec = db.query(CallRecord).filter(CallRecord.id == call_id).first()
        if not call_rec:
            # Fallback if call not pre-registered
            call_rec = CallRecord(
                id=call_id,
                caller_number="Unknown",
                call_type="screened",
                status="active"
            )
            db.add(call_rec)

        # 1. Log caller's dialogue turn
        caller_dialogue = AssistantDialogue(
            call_id=call_id,
            speaker="caller",
            text=caller_transcript,
            language=detected_language,
            confidence=0.95
        )
        db.add(caller_dialogue)

        # 2. Update Risk Assessment
        eval_result = risk_engine.evaluate(
            db=db,
            phone_number=call_rec.caller_number,
            live_transcript=caller_transcript,
            is_deepfake=is_deepfake,
            deepfake_confidence=deepfake_confidence,
            caller_name=call_rec.caller_name
        )

        score = eval_result["final_score"]
        level = eval_result["risk_level"]
        color = eval_result["color_code"]
        scam_detected = eval_result["scam_intent_detected"]
        scam_cat = eval_result["scam_category"]

        # 3. Determine Assistant Reaction & Decision
        decision = "CONTINUE_QUESTIONING"
        scam_alert = None

        if level == "HIGH" or scam_detected or (is_deepfake and deepfake_confidence > 80.0):
            decision = "TERMINATE_CALL_SCAM"
            scam_alert = f"Detected {scam_cat or 'Fraudulent/Deepfake Activity'}"
            if detected_language == "es":
                reply = "Esta llamada ha sido identificada como una posible estafa y se está desconectando. Adiós."
            elif detected_language == "hi":
                reply = "यह कॉल एक संभावित धोखाधड़ी के रूप में पहचानी गई है और इसे समाप्त किया जा रहा है।"
            elif detected_language == "fr":
                reply = "Cet appel a été identifié comme une tentative de fraude et va être interrompu."
            elif detected_language == "de":
                reply = "Dieser Anruf wurde als potenzieller Betrug eingestuft und wird beendet."
            else:
                reply = "This call has been identified as potential fraud and is being disconnected to protect the subscriber."
        elif level == "LOW":
            decision = "PASS_TO_USER"
            if detected_language == "es":
                reply = "Gracias por identificarse. Estoy transfiriendo su llamada al usuario ahora mismo."
            elif detected_language == "hi":
                reply = "धन्यवाद। मैं अब आपकी कॉल यूजर को ट्रांसफर कर रहा हूँ।"
            elif detected_language == "fr":
                reply = "Merci. Je vous mets en relation avec le destinataire dès maintenant."
            elif detected_language == "de":
                reply = "Vielen Dank. Ich verbinde Sie jetzt mit dem Teilnehmer."
            else:
                reply = "Thank you. Connecting your call to the recipient now."
        else:
            # MEDIUM risk - ask for verification or specifics
            decision = "CONTINUE_QUESTIONING"
            if detected_language == "es":
                reply = "Entendido. ¿Podría indicar a qué empresa o asunto específico se refiere?"
            elif detected_language == "hi":
                reply = "कृपया स्पष्ट करें कि आप किस विषय के संबंध में संपर्क कर रहे हैं?"
            elif detected_language == "fr":
                reply = "Bien reçu. Pourriez-vous préciser le motif précis ou le nom de votre société ?"
            elif detected_language == "de":
                reply = "Verstanden. Könnten Sie bitte den genauen Anlass oder Ihr Unternehmen nennen?"
            else:
                reply = "Understood. Could you specify which company or matter this is regarding so I can notify the user?"

        # 4. Log Assistant response
        asst_dialogue = AssistantDialogue(
            call_id=call_id,
            speaker="assistant",
            text=reply,
            language=detected_language,
            confidence=1.0
        )
        db.add(asst_dialogue)

        # 5. Update CallRecord
        call_rec.final_risk_score = score
        call_rec.risk_level = level
        call_rec.is_deepfake = bool(is_deepfake)
        call_rec.deepfake_confidence = deepfake_confidence
        call_rec.scam_detected = scam_detected
        call_rec.scam_category = scam_cat
        if decision == "TERMINATE_CALL_SCAM":
            call_rec.status = "blocked"
        elif decision == "PASS_TO_USER":
            call_rec.status = "answered"

        db.commit()

        return {
            "assistant_reply": reply,
            "decision": decision,
            "updated_risk_score": score,
            "risk_level": level,
            "color_code": color,
            "scam_alert": scam_alert
        }

ai_assistant = AIAssistantDialogueManager()
