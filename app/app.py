import os

from flask import Flask, jsonify, render_template, redirect, request, url_for

import db

app = Flask(__name__)

APP_ENV = os.getenv("APP_ENV", "dev")
BG_COLOR = os.getenv("BG_COLOR", "lightblue")
USE_DATABASE = db.is_configured()


def storage_mode() -> str:
    return "postgresql" if USE_DATABASE else "memory"


def _list_todos() -> list[dict]:
    return db.list_todos() if USE_DATABASE else []


@app.route("/health")
def health():
    if not USE_DATABASE:
        return jsonify({"status": "error", "error": "DB not configured"}), 503

    db_status = db.ping()
    ok = db_status["connected"]
    return (
        jsonify(
            {
                "status": "ok" if ok else "degraded",
                "env": APP_ENV,
                "storage": storage_mode(),
                "database": db_status,
            }
        ),
        200 if ok else 503,
    )


@app.route("/")
def index():
    return render_template(
        "index.html",
        todos=_list_todos(),
        env=APP_ENV,
        bg=BG_COLOR,
        storage=storage_mode(),
    )


@app.route("/add", methods=["POST"])
def add():
    task_text = request.form.get("task", "").strip()
    if task_text and USE_DATABASE:
        db.add_todo(task_text)
    return redirect(url_for("index"))


@app.route("/check/<int:todo_id>")
def check(todo_id):
    if USE_DATABASE:
        db.toggle_todo(todo_id)
    return redirect(url_for("index"))


@app.route("/delete/<int:todo_id>")
def delete(todo_id):
    if USE_DATABASE:
        db.delete_todo(todo_id)
    return redirect(url_for("index"))


def create_app() -> Flask:
    if not USE_DATABASE:
        raise RuntimeError("DB_HOST or DATABASE_URL is required")
    db.init_pool()
    db.init_schema()
    db.seed_defaults()
    return app
