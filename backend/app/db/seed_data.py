from datetime import datetime, timedelta
from app.db.session import SessionLocal, Base, engine
from app.db.models import SpamRecord, ContactWhitelist, CallRecord, AssistantDialogue, CommunityReport

def seed_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        # Check if already seeded
        if db.query(SpamRecord).first():
            return

        # 1. Seed Known Spam Numbers
        spam_samples = [
            SpamRecord(
                phone_number="+18005550199",
                name_tag="IRS Tax Relief Scam",
                category="Government Impersonation",
                reports_count=428,
                base_risk_score=95.0,
            ),
            SpamRecord(
                phone_number="+18882001122",
                name_tag="Automated Robocall - Health Insurance",
                category="Robocall",
                reports_count=182,
                base_risk_score=82.0,
            ),
            SpamRecord(
                phone_number="+12025550143",
                name_tag="Suspicious Bank Security Alert",
                category="Financial Fraud",
                reports_count=94,
                base_risk_score=88.5,
            ),
            SpamRecord(
                phone_number="+442079460912",
                name_tag="Crypto Investment Advisory",
                category="Investment Scam",
                reports_count=67,
                base_risk_score=79.0,
            ),
            SpamRecord(
                phone_number="+919876543210",
                name_tag="Electricity Bill Disconnection Fraud",
                category="Utility Scam",
                reports_count=230,
                base_risk_score=92.0,
            ),
            SpamRecord(
                phone_number="+13125550178",
                name_tag="Apex Telemarketing Ltd",
                category="Telemarketing",
                reports_count=45,
                base_risk_score=55.0,
            ),
        ]
        db.add_all(spam_samples)

        # 2. Seed Whitelist Contacts
        whitelist_samples = [
            ContactWhitelist(
                phone_number="+14155552671",
                contact_name="Sarah Miller (Mom)",
                relationship="Family"
            ),
            ContactWhitelist(
                phone_number="+14155559823",
                contact_name="Dr. Robert Chen",
                relationship="Healthcare"
            ),
            ContactWhitelist(
                phone_number="+14155554321",
                contact_name="Acme Corp Office Desk",
                relationship="Work"
            ),
        ]
        db.add_all(whitelist_samples)

        # 3. Seed Sample Call Records
        now = datetime.utcnow()
        sample_call = CallRecord(
            id="sample-call-001",
            caller_number="+18005550199",
            caller_name="IRS Tax Relief Scam",
            call_type="screened",
            status="blocked",
            timestamp=now - timedelta(hours=2),
            duration_seconds=38,
            final_risk_score=94.0,
            risk_level="HIGH",
            is_deepfake=True,
            deepfake_confidence=89.4,
            scam_detected=True,
            scam_category="Government Impersonation",
            transcript_summary="Caller claimed to be Agent Davis from IRS demanding immediate payment via gift cards or wire transfer."
        )
        db.add(sample_call)

        dialogues = [
            AssistantDialogue(
                call_id="sample-call-001",
                speaker="assistant",
                text="Hello, I am the VoxGuard AI Assistant. Who is calling and what is the reason for your call?",
                language="en",
                confidence=1.0,
                timestamp=now - timedelta(hours=2, seconds=35)
            ),
            AssistantDialogue(
                call_id="sample-call-001",
                speaker="caller",
                text="This is Officer Davis from Federal Tax Department. There is an urgent warrant for your arrest regarding unpaid taxes.",
                language="en",
                confidence=0.96,
                timestamp=now - timedelta(hours=2, seconds=25)
            ),
            AssistantDialogue(
                call_id="sample-call-001",
                speaker="assistant",
                text="This call has been identified as potential fraudulent activity and is being terminated to protect the subscriber.",
                language="en",
                confidence=1.0,
                timestamp=now - timedelta(hours=2, seconds=5)
            ),
        ]
        db.add_all(dialogues)

        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()
