from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models import SpamRecord, ContactWhitelist, CallRecord
from app.services.scam_analyzer import scam_analyzer
from app.core.logging import logger

class DynamicRiskEngine:
    """
    Computes a real-time, multi-factor Risk Score (0 - 100) for incoming calls.
    Combines:
    1. Historical Spam Database & Community Flag Reports
    2. Short-window Burst Call Frequency & Recency Velocity
    3. AI Deepfake / Synthetic Voice Detection
    4. Real-time NLU Live Transcript Scam Intent Analysis
    5. Contact Whitelist / Trusted Relationship Discount
    """

    COLOR_MAP = {
        "LOW": "#10B981",     # 🟢 Emerald Green (Safe)
        "MEDIUM": "#F59E0B",  # 🟡 Amber Yellow (Suspicious)
        "HIGH": "#EF4444"     # 🔴 Crimson Red (Scam/Deepfake)
    }

    def evaluate(
        self,
        db: Session,
        phone_number: str,
        live_transcript: Optional[str] = None,
        is_deepfake: Optional[bool] = False,
        deepfake_confidence: Optional[float] = 0.0,
        caller_name: Optional[str] = None
    ) -> Dict[str, Any]:
        flags: List[str] = []
        normalized_num = phone_number.strip().replace(" ", "").replace("-", "")

        # 1. Check Contact Whitelist
        is_whitelisted = False
        whitelist_entry = db.query(ContactWhitelist).filter(
            ContactWhitelist.phone_number == normalized_num
        ).first()

        whitelist_discount = 0.0
        if whitelist_entry:
            is_whitelisted = True
            whitelist_discount = 85.0
            flags.append(f"Verified Contact: {whitelist_entry.contact_name} ({whitelist_entry.relationship})")

        # 2. Query Spam Database
        spam_entry = db.query(SpamRecord).filter(
            SpamRecord.phone_number == normalized_num
        ).first()

        db_score = 10.0  # Baseline unknown caller
        if spam_entry:
            db_score = spam_entry.base_risk_score
            flags.append(f"Spam DB Hit: {spam_entry.name_tag} ({spam_entry.reports_count} reports)")
        elif not is_whitelisted:
            flags.append("Unknown Number (Not in contacts)")

        # 3. Call Frequency & Burst Velocity (last 30 minutes)
        window_start = datetime.utcnow() - timedelta(minutes=settings.BURST_CALL_WINDOW_MINUTES)
        recent_call_count = db.query(CallRecord).filter(
            CallRecord.caller_number == normalized_num,
            CallRecord.timestamp >= window_start
        ).count()

        frequency_penalty = 0.0
        if recent_call_count >= settings.BURST_CALL_THRESHOLD:
            frequency_penalty = min(recent_call_count * 10.0, 30.0)
            flags.append(f"High Frequency Velocity: {recent_call_count} calls in past {settings.BURST_CALL_WINDOW_MINUTES} mins")

        # 4. Deepfake Voice Penalty
        deepfake_penalty = 0.0
        if is_deepfake and deepfake_confidence and deepfake_confidence > 50.0:
            deepfake_penalty = min(deepfake_confidence * 0.75, 45.0)
            flags.append(f"AI Deepfake Voice Detected ({deepfake_confidence:.1f}% confidence)")

        # 5. NLP Scam Intent Analysis
        scam_penalty = 0.0
        scam_detected = False
        scam_category = None
        if live_transcript:
            scam_res = scam_analyzer.analyze_transcript(live_transcript)
            if scam_res["is_scam"]:
                scam_detected = True
                scam_category = scam_res["scam_category"]
                scam_penalty = scam_res["risk_penalty"]
                flags.append(f"Scam Pattern Alert: {scam_category}")

        # Compute Raw Weighted Score
        raw_score = db_score + frequency_penalty + deepfake_penalty + scam_penalty

        # Apply Whitelist Discount
        # Note: If an active deepfake or scam language is found on a whitelisted contact,
        # it could be a voice cloning / SIM swap attack, so we do not zero out completely!
        if is_whitelisted:
            if is_deepfake or scam_detected:
                whitelist_discount = 40.0
                flags.append("WARNING: Possible Family Impersonation / Voice Cloning Attack!")
            final_score = max(raw_score - whitelist_discount, 5.0)
        else:
            final_score = min(max(raw_score, 0.0), 100.0)

        final_score = round(final_score, 1)

        # Categorize Risk Level
        if final_score <= settings.LOW_RISK_MAX:
            risk_level = "LOW"
            recommendation = "ALLOW"
        elif final_score <= settings.MEDIUM_RISK_MAX:
            risk_level = "MEDIUM"
            recommendation = "SCREEN_WITH_AI"
        else:
            risk_level = "HIGH"
            recommendation = "BLOCK"

        color_code = self.COLOR_MAP[risk_level]

        return {
            "phone_number": normalized_num,
            "final_score": final_score,
            "risk_level": risk_level,
            "color_code": color_code,
            "recommendation": recommendation,
            "breakdown": {
                "database_score": round(db_score, 1),
                "frequency_velocity_penalty": round(frequency_penalty, 1),
                "deepfake_penalty": round(deepfake_penalty, 1),
                "scam_intent_penalty": round(scam_penalty, 1),
                "whitelist_discount": round(whitelist_discount, 1)
            },
            "flags": flags,
            "is_deepfake": bool(is_deepfake),
            "scam_intent_detected": scam_detected,
            "scam_category": scam_category,
            "caller_name": caller_name or (whitelist_entry.contact_name if whitelist_entry else (spam_entry.name_tag if spam_entry else "Unknown Caller"))
        }

risk_engine = DynamicRiskEngine()
