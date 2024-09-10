# app/routes.py
from flask import Blueprint, jsonify
from .services import get_trends

main = Blueprint('main', __name__)

@main.route('/trends/<symbol>', methods=['GET'])
def trends(symbol):
    data = get_trends(symbol)
    return jsonify(data)