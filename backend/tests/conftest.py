import pytest
from app.db.session import engine, Base
from app.db.seed_data import seed_database

@pytest.fixture(autouse=True)
def setup_test_database():
    Base.metadata.create_all(bind=engine)
    seed_database()
    yield
