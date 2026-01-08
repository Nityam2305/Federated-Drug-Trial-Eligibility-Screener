import json
import numpy as np
from sklearn.ensemble import RandomForestClassifier

def load_medical_data():
    with open('medical_data.json', 'r') as f:
        data = json.load(f)
    return data['hospitals']

def preprocess_hospital_data(patients):
    features = []
    labels = []
    
    for patient in patients:
        age = patient.get('age', 0)
        gender = 1 if patient.get('gender') == 'Male' else 0
        bmi = patient.get('bmi', 25)
        stage = {'I': 1, 'II': 2, 'III': 3, 'IV': 4}.get(patient.get('stage', 'I'), 1)
        comorbidities_count = len(patient.get('comorbidities', []))
        disease = patient.get('disease', '')
        disease_code = hash(disease) % 100
        
        feature_vector = [age, gender, bmi, stage, comorbidities_count, disease_code]
        features.append(feature_vector)
        labels.append(patient.get('eligible', 0))
    
    return np.array(features), np.array(labels)

def train_federated_model(hospitals_data):
    all_features = []
    all_labels = []
    
    for hospital, patients in hospitals_data.items():
        X, y = preprocess_hospital_data(patients)
        all_features.append(X)
        all_labels.append(y)
    
    X_combined = np.vstack(all_features)
    y_combined = np.concatenate(all_labels)
    
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_combined, y_combined)
    
    print("Federated model trained successfully")
    return model

global_model = None

def initialize_and_train_model():
    global global_model
    hospitals_data = load_medical_data()
    global_model = train_federated_model(hospitals_data)

def predict_eligibility(patient_data):
    if global_model is None:
        return {"error": "Model not trained yet"}
    
    age = patient_data.get('age', 0)
    gender = 1 if patient_data.get('gender') == 'Male' else 0
    bmi = patient_data.get('bmi', 25)
    stage = {'I': 1, 'II': 2, 'III': 3, 'IV': 4}.get(patient_data.get('stage', 'I'), 1)
    comorbidities_count = len(patient_data.get('comorbidities', []))
    disease = patient_data.get('disease', '')
    disease_code = hash(disease) % 100
    
    features = np.array([[age, gender, bmi, stage, comorbidities_count, disease_code]])
    
    prediction = global_model.predict_proba(features)[0][1]
    eligible = 1 if prediction > 0.5 else 0
    
    return {
        "eligible": eligible,
        "confidence": float(prediction)
    }