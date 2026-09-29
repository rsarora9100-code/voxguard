import pytest
from app.services.scam_analyzer import scam_analyzer

def test_otp_theft_detection():
    text = "Hello sir, we detected unusual activity on your bank card. Please read back the OTP verification code sent to your phone."
    res = scam_analyzer.analyze_transcript(text)
    assert res["is_scam"] is True
    assert res["scam_category"] == "OTP_AND_CREDENTIAL_THEFT"
    assert res["confidence"] >= 90.0

def test_police_impersonation_detection():
    text = "This is Federal Agent Miller from Internal Revenue Service. There is an active arrest warrant against your Social Security Number."
    res = scam_analyzer.analyze_transcript(text)
    assert res["is_scam"] is True
    assert res["scam_category"] == "GOVERNMENT_LAW_ENFORCEMENT_IMPERSONATION"
    assert res["risk_penalty"] > 50.0

def test_urgent_wire_gift_card():
    text = "You must go to the nearest store, buy Target gift cards and send money immediately to settle your fine."
    res = scam_analyzer.analyze_transcript(text)
    assert res["is_scam"] is True
    assert res["scam_category"] == "URGENT_FINANCIAL_FRAUD"

def test_remote_access_malware():
    text = "Your Windows system is infected with dangerous Trojan. Please download AnyDesk so we can connect to your computer."
    res = scam_analyzer.analyze_transcript(text)
    assert res["is_scam"] is True
    assert res["scam_category"] == "REMOTE_ACCESS_MALWARE"

def test_spanish_scam():
    text = "Urgente, soy el agente de la policía federal y hay una orden de arresto si no hace la transferencia ahora mismo."
    res = scam_analyzer.analyze_transcript(text, language="es")
    assert res["is_scam"] is True

def test_hindi_scam():
    text = "Apka bank account block ho gaya hai, apna OTP batao turant."
    res = scam_analyzer.analyze_transcript(text, language="hi")
    assert res["is_scam"] is True
    assert res["scam_category"] == "OTP_AND_CREDENTIAL_THEFT"

def test_innocuous_speech():
    text = "Hi Mark, just calling to see if you want to grab lunch at 12:30 today at the Italian place downtown."
    res = scam_analyzer.analyze_transcript(text)
    assert res["is_scam"] is False
    assert res["risk_penalty"] == 0.0
