from flask import Flask, request, jsonify
import os

# 12-Factor: configuración vía variables de entorno (sin valores codificados)
HOST = os.environ.get("HOST","127.0.0.1")
PORT = int(os.environ.get("PORT", "8080"))

app = Flask(__name__)

courses = {
    1: {"Nombre": "Desarrollo de software", "Codigo": "CC3S2"},
    2: {"Nombre": "Computacion Grafica", "Codigo": "CC431"} 
}

next_id = 3

used_course_codes = {"CC3S2", "CC431"}

idempotency_store = {}

def save_idempotent_response(key, response, status_code):
    idempotency_store[key] = {
        'response': response,
        'status_code': status_code
    }

def get_idempotent_response(key):
    return idempotency_store.get(key)

# Metodo GET
@app.route("/courses", methods=['GET'])
def get_courses():

    try:
        courses_list = [{"id": id, **course} for id, course in courses.items()]
        return jsonify(courses_list), 200
    except Exception as e:
        return jsonify({"error": "Error al procesar la solicitud"}), 500

# Metodo POST
@app.route("/create", methods=['POST'])
def create_course():
    global next_id

    try:
        idempotency_key = request.headers.get("Idempotency-Key")

        if not idempotency_key:
            return jsonify({"error": "Falta la clave de la cabecera 'Idempotency-Key'"}), 422

        response = get_idempotent_response(idempotency_key)
        if response:
            return jsonify(response['response']), response["status_code"]

        data = request.get_json()
        if data is None:
            return jsonify({"error": "No se proporciono JSON valido"}), 400

        codigo = data.get('Codigo')
        if not codigo:
            return jsonify({"error": "Se requiere 'Codigo' en el JSON"}), 400
        if codigo in used_course_codes:
            return jsonify({"error": "El codigo del curso ya existe"}), 409
        
        nombre = data.get('Nombre')
        if not nombre:
            return jsonify({"error": "Se requiere 'Nombre' en el JSON"}), 400
        
        new_course = {
            "Nombre": nombre,
            "Codigo": codigo
        }

        courses[next_id] = new_course
        used_course_codes.add(codigo)
        course_id = next_id
        next_id += 1

        success_response = {
            "mensaje": "Curso creado exitosamente",
            "id": course_id,
            "curso": new_course
        }

        if idempotency_key:
            save_idempotent_response(idempotency_key, success_response, 201)
            print(f"[IDEMPOTENCIA] Almacenada clave: {idempotency_key}")

        return jsonify(success_response), 201        
        
    except Exception as e:
        return jsonify({"error": "Error al procesar la solicitud"}), 500
    
# Metodo PUT
@app.route("/update", methods=['PUT'])
def update_course():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No se proporciono JSON valido"}), 400
        
        codigo = data.get('Codigo')
        if not codigo:
            return jsonify({"error": "Se requiere 'Codigo' en el JSON"}), 400
        if not codigo in used_course_codes:
            return jsonify({"error": "Ese 'Codigo' no existe"}), 404
        
        nombre = data.get('Nombre')
        if not nombre:
            return jsonify({"error": "Se requiere 'Nombre' en el JSON"}), 400
        
        for course_id, course_data in courses.items():
            if course_data.get('Codigo') == codigo:
                courses[course_id]['Nombre'] = nombre
                success_response = {
                    "mensaje": "Curso actualizado exitosamente",
                    "id": course_id,
                    "curso": courses[course_id]
                }
                return jsonify(success_response), 200  
            
        return jsonify({"error": "Error interno: curso no encontrado"}), 500

    except Exception as e:
        return jsonify({"error": "Error al procesar la solicitud"}), 500


if __name__ == "__main__":
    app.run(host=HOST, port=PORT)