import logging

from sqlalchemy import func, select

from shopcommon.app import create_app
from shopcommon.config import env
from shopcommon.db import session_scope

from .api import router
from .models import Product

log = logging.getLogger(__name__)

SAMPLE_PRODUCTS = [
    ("SER-001", "Hyaluronic Hydrating Serum", "Lightweight daily serum, 30ml.", 1800, 50),
    ("LIP-001", "Velvet Matte Lipstick", "Rosewood shade, long-wear.", 1400, 80),
    ("CRM-001", "Shea Butter Night Cream", "Rich overnight moisturiser, 50ml.", 2400, 40),
    ("CLN-001", "Gentle Foaming Cleanser", "Soap-free, for all skin types, 150ml.", 1200, 70),
    ("MAS-001", "Lengthening Mascara", "Smudge-proof, jet black.", 1600, 60),
    ("SPF-001", "Daily Mineral Sunscreen SPF 50", "No white cast, 50ml.", 2000, 45),
]


def seed_catalogue() -> None:
    if (env("SEED_SAMPLE_DATA", "true") or "").lower() != "true":
        return
    with session_scope() as db:
        if db.scalar(select(func.count()).select_from(Product)):
            return
        for sku, name, desc, price, stock in SAMPLE_PRODUCTS:
            db.add(Product(sku=sku, name=name, description=desc, price_pence=price, stock=stock,
                           active=True))
        db.commit()
        log.info("seeded %d sample products", len(SAMPLE_PRODUCTS))


app = create_app("products", [router], on_startup=seed_catalogue)
