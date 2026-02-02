from db.session import Base, DB_PATH, engine


def main() -> None:
    # Ensure schema changes apply: drop all tables, then recreate.
    # If the sqlite file exists, remove it as well.
    Base.metadata.drop_all(bind=engine)

    if DB_PATH.exists():
        DB_PATH.unlink()
        print(f"Deleted {DB_PATH}")

    Base.metadata.create_all(bind=engine)
    print(f"Created fresh database schema at {DB_PATH}")


if __name__ == "__main__":
    main()
