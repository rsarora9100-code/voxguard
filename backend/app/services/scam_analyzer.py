import re
from typing import Dict, Any, List
from app.core.logging import logger

class NLPScamAnalyzer:
    """
    Natural Language Understanding (NLU) engine for real-time scam intent detection.
    Scans live transcripts for high-risk social engineering markers, financial coercion,
    OTP requests, and law enforcement impersonation in multiple languages.
    """

    # Multi-language scam patterns
    SCAM_PATTERNS = {
        "OTP_AND_CREDENTIAL_THEFT": {
            "weight": 95.0,
            "patterns": [
                r"\b(?:otp|one[- ]time[- ]password|verification code|security code)\b",
                r"\b(?:cvv|card verification|3-digit code|expiry date)\b",
                r"\b(?:read (?:me|back) the (?:code|number))\b",
                r"\b(?:código de verificación|contraseña temporal)\b",
                r"\b(?:otp batao|apna code bhejo|otp share)\b",
                r"\b(?:code de vérification|mot de passe unique)\b",
                r"\b(?:einmalpasswort|bestätigungscode)\b"
            ]
        },
        "GOVERNMENT_LAW_ENFORCEMENT_IMPERSONATION": {
            "weight": 90.0,
            "patterns": [
                r"\b(?:irs|internal revenue service|fbi|cia|homeland security|federal agent)\b",
                r"\b(?:arrest warrant|police department|law enforcement|sheriff)\b",
                r"\b(?:legal action against your social security|ssn suspended)\b",
                r"\b(?:orden de arresto|departamento de policía|agente federal)\b",
                r"\b(?:police custody|jail|court summons|customs seizure)\b",
                r"\b(?:mandat d'arrêt|procureur|gendarmerie)\b",
                r"\b(?:haftbefehl|bundeskriminalamt|finanzamt)\b"
            ]
        },
        "URGENT_FINANCIAL_FRAUD": {
            "weight": 85.0,
            "patterns": [
                r"\b(?:wire transfer|send money immediately|urgent wire|zelle|crypto transfer)\b",
                r"\b(?:buy gift cards|target gift card|apple gift card|google play card)\b",
                r"\b(?:pay the fine right now|immediate payment required)\b",
                r"\b(?:transferencia urgente|tarjeta de regalo|pague la multa)\b",
                r"\b(?:virement urgent|cartes-cadeaux|carte apple)\b",
                r"\b(?:sofortüberweisung|gutscheinkarten|geschenkkarten)\b"
            ]
        },
        "REMOTE_ACCESS_MALWARE": {
            "weight": 80.0,
            "patterns": [
                r"\b(?:anydesk|teamviewer|quicksupport|ultraviewer|rustdesk)\b",
                r"\b(?:download the software to fix your computer|remote access)\b",
                r"\b(?:your computer has a dangerous virus|microsoft technical support)\b",
                r"\b(?:soporte técnico de windows|descargue anydesk)\b"
            ]
        },
        "FAMILY_EMERGENCY_EXTORTION": {
            "weight": 90.0,
            "patterns": [
                r"\b(?:your son is in jail|daughter had an accident|kidnapped|held hostage)\b",
                r"\b(?:need bail money immediately|don't hang up)\b",
                r"\b(?:su hijo está en la cárcel|accidente grave|rescate)\b",
                r"\b(?:votre fils est en prison|caution immédiate)\b"
            ]
        },
        "LOTTERY_PRIZE_SCAM": {
            "weight": 65.0,
            "patterns": [
                r"\b(?:won a million dollars|lottery winner|exclusive prize)\b",
                r"\b(?:claim your reward|pay processing fee to receive prize)\b",
                r"\b(?:has ganado la lotería|premio exclusivo)\b"
            ]
        }
    }

    URGENCY_MARKERS = [
        r"\b(?:right now|immediately|do not hang up|within the hour|urgent|emergency)\b",
        r"\b(?:ahora mismo|inmediatamente|no cuelgue)\b",
        r"\b(?:tout de suite|immédiatement|ne raccrochez pas)\b",
        r"\b(?:sofort|dringend|legen sie nicht auf)\b"
    ]

    def analyze_transcript(self, text: str, language: str = "en") -> Dict[str, Any]:
        """
        Analyzes spoken transcript to detect scam indicators and calculate risk penalty.
        """
        if not text or len(text.strip()) == 0:
            return {
                "is_scam": False,
                "confidence": 0.0,
                "scam_category": None,
                "matched_patterns": [],
                "risk_penalty": 0.0,
                "explanation": "No speech detected yet."
            }

        text_lower = text.lower()
        matched_categories = []
        all_matched_keywords = []
        highest_weight = 0.0
        primary_category = None

        # 1. Check scam category regexes
        for category, info in self.SCAM_PATTERNS.items():
            category_matches = []
            for pattern in info["patterns"]:
                found = re.findall(pattern, text_lower)
                if found:
                    category_matches.extend(found)

            if category_matches:
                matched_categories.append(category)
                all_matched_keywords.extend(category_matches)
                if info["weight"] > highest_weight:
                    highest_weight = info["weight"]
                    primary_category = category

        # 2. Check urgency multiplier
        urgency_detected = False
        for u_pat in self.URGENCY_MARKERS:
            if re.search(u_pat, text_lower):
                urgency_detected = True
                break

        # Calculate final confidence and risk penalty
        if matched_categories:
            base_conf = highest_weight
            if urgency_detected:
                base_conf = min(base_conf + 5.0, 99.0)
            
            # Risk penalty: up to 80 points added to risk engine
            risk_penalty = min(base_conf * 0.85, 80.0)

            explanation = (
                f"Suspicious intent detected ({primary_category}): "
                f"keywords found [{', '.join(set(all_matched_keywords[:4]))}]. "
                f"{'Urgency tactics identified.' if urgency_detected else ''}"
            )

            return {
                "is_scam": True,
                "confidence": round(base_conf, 1),
                "scam_category": primary_category,
                "matched_patterns": list(set(all_matched_keywords)),
                "risk_penalty": round(risk_penalty, 1),
                "explanation": explanation
            }
        
        return {
            "is_scam": False,
            "confidence": 10.0,
            "scam_category": None,
            "matched_patterns": [],
            "risk_penalty": 0.0,
            "explanation": "No suspicious scam patterns identified in caller speech."
        }

scam_analyzer = NLPScamAnalyzer()
