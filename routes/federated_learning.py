from flask import Blueprint, jsonify, request
import federated_learning
import json
import os
from datetime import datetime

fl_bp = Blueprint('federated_learning', __name__)

@fl_bp.route('/train-model', methods=['POST'])
def train_model():
    try:
        federated_learning.initialize_and_train_model()
        return jsonify({"message": "Model trained successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@fl_bp.route('/predict', methods=['POST'])
def predict():
    try:
        patient_data = request.json
        result = federated_learning.predict_eligibility(patient_data)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@fl_bp.route('/patients', methods=['GET'])
def get_patients():
    try:
        with open('medical_data.json', 'r') as f:
            data = json.load(f)
        
        # Flatten patients from all hospitals
        all_patients = []
        for hospital, patients in data['hospitals'].items():
            for patient in patients:
                patient['hospital'] = hospital
                all_patients.append(patient)
        
        return jsonify({"patients": all_patients})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@fl_bp.route('/trials', methods=['GET'])
def get_trials():
    try:
        with open('medical_data.json', 'r') as f:
            data = json.load(f)
        
        # Calculate trial statistics from actual data
        trials_stats = {}
        
        for hospital, patients in data['hospitals'].items():
            for patient in patients:
                drug = patient.get('drug', 'Unknown')
                disease = patient.get('disease', 'Unknown Disease')
                eligible = patient.get('eligible', 0)
                drug_worked = patient.get('drug_worked', 0)
                
                if drug not in trials_stats:
                    trials_stats[drug] = {
                        'drugName': drug,
                        'indication': disease,
                        'phase': 'Phase III',  # Default phase
                        'status': 'Active',
                        'patientsEnrolled': 0,
                        'eligiblePatients': 0,
                        'successCount': 0,
                        'successRate': 0,
                        'startDate': '2024-01-01',
                        'lastUpdate': datetime.now().strftime('%Y-%m-%d')
                    }
                
                trials_stats[drug]['patientsEnrolled'] += 1
                if eligible:
                    trials_stats[drug]['eligiblePatients'] += 1
                if drug_worked:
                    trials_stats[drug]['successCount'] += 1
        
        # Calculate success rates
        trials = []
        for drug, stats in trials_stats.items():
            if stats['patientsEnrolled'] > 0:
                stats['successRate'] = round((stats['successCount'] / stats['patientsEnrolled']) * 100, 1)
            
            trials.append({
                'id': len(trials) + 1,
                **stats
            })
        
        return jsonify({"trials": trials})
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@fl_bp.route('/upload-json', methods=['POST'])
def upload_json():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
        
        if not file.filename.endswith('.json'):
            return jsonify({"error": "File must be a JSON file"}), 400
        
        # Save the uploaded file temporarily
        temp_path = os.path.join(os.getcwd(), 'temp_upload.json')
        file.save(temp_path)
        
        # Load and validate the JSON data
        with open(temp_path, 'r') as f:
            uploaded_data = json.load(f)
        
        # Validate the structure (should have hospitals key)
        if 'hospitals' not in uploaded_data:
            os.remove(temp_path)
            return jsonify({"error": "Invalid JSON structure. Must contain 'hospitals' key"}), 400
        
        # Merge with existing data or replace
        try:
            with open('medical_data.json', 'r') as f:
                existing_data = json.load(f)
        except FileNotFoundError:
            existing_data = {"hospitals": {}}
        
        # Merge the data
        for hospital, patients in uploaded_data['hospitals'].items():
            if hospital in existing_data['hospitals']:
                # Append new patients
                existing_data['hospitals'][hospital].extend(patients)
            else:
                # Add new hospital
                existing_data['hospitals'][hospital] = patients
        
        # Save the merged data
        with open('medical_data.json', 'w') as f:
            json.dump(existing_data, f, indent=2)
        
        # Clean up temp file
        os.remove(temp_path)
        
        # Retrain the model with new data
        federated_learning.initialize_and_train_model()
        
        return jsonify({
            "message": "JSON file uploaded and model retrained successfully",
            "hospitals_added": len(uploaded_data['hospitals']),
            "total_patients": sum(len(patients) for patients in existing_data['hospitals'].values())
        })
        
    except json.JSONDecodeError:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return jsonify({"error": "Invalid JSON file"}), 400
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return jsonify({"error": str(e)}), 500