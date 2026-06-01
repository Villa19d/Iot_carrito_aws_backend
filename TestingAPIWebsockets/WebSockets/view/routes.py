from flask import Blueprint, request, jsonify
import asyncio
from flask import render_template

def create_routes(controller):
    bp = Blueprint("routes", __name__)

    # 🔹 Obtener estado actual
    @bp.route("/status", methods=["GET"])
    def get_status():
        return jsonify(controller.get_status())
    
    @bp.route("/", methods=["GET"])
    def index():
        return render_template("index.html")

    # 🔹 Cambiar estado (vía GET)
    @bp.route("/set_status", methods=["GET"])
    def set_status():
        try:
            # Obtener parámetro ?value=true/false
            value = request.args.get("value", "false").lower() == "true"

            # Ejecutar función async correctamente
            data = asyncio.run(controller.update_status(value))

            return jsonify(data)

        except Exception as e:
            # Manejo básico de errores (muy útil para debug)
            return jsonify({
                "error": str(e)
            }), 500

    return bp