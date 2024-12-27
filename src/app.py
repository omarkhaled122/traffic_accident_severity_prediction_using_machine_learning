# -*- coding: utf-8 -*-
import os
import pickle

from flask import Flask, jsonify, request

from cli import load_config

app = Flask(__name__)


@app.route('/health')
def health():
    return jsonify(status='OK')


@app.route('/predict', methods=['POST'])
def predict():
    logger = app.config['logger']
    feature_extractor = app.config['feature_extractor']
    model = app.config['model']

    data = request.get_json()
    logger.info('got data {}'.format(data))

    logger.info('extracting features...')
    features = feature_extractor.transform(data)

    logger.info('predicting...')
    prediction = model.predict(features)

    return jsonify(prediction=prediction)


def load_app_config():
    config_definitions = {
        'FEATURE_EXTRACTOR': str,
        'MODEL': str,
        'APP_PORT': int,
        'ENVIRONMENT': str
    }
    config = {k: v(os.environ[k]) for k, v in config_definitions.items()}
    app.config.update(config)

    app.config['model'] = pickle.load(app.config['model'])
    app.config['feature_extractor'] = pickle.load(
        app.config['feature_extractor'])


load_config()
load_app_config()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=app.config['APP_PORT'])
