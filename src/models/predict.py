# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Makes a prediction')
@click.argument('model_path', type=click.Path(exists=True))
@click.argument('feature_extractor_path', type=click.Path(exists=True))
@click.argument('data_to_predict_path', type=click.Path(exists=True))
@click.argument('prediction_path', type=click.Path())
def predict(model_path, feature_extractor_path, data_to_predict_path,
            prediction_path):
    """Makes a prediction.

    Reads a model from MODEL_PATH, a feature extractor pipeline from
    FEATURE_EXTRACTOR_PATH, the data to make a prediction for from
    DATA_TO_PREDICT_PATH, and saves the prediction in
    PREDICTION_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading model from {}'.format(model_path))
    logger.info('reading feature extractor pipeline from {}'.format(
        feature_extractor_path))
    logger.info('reading data to predict from {}'.format(data_to_predict_path))
    logger.info('saving prediction in {}'.format(prediction_path))


@click.command(short_help='Tests a model')
@click.argument('model_path', type=click.Path(exists=True))
@click.argument('feature_extractor_path', type=click.Path(exists=True))
@click.argument('testset_path', type=click.Path(exists=True))
@click.argument('predictions_path', type=click.Path())
@click.argument('report_path', type=click.Path())
def test_model(model_path, feature_extractor_path, testset_path,
               predictions_path, report_path):
    """Tests a model.

    Reads a model from MODEL_PATH, a feature extractor pipeline from
    FEATURE_EXTRACTOR_PATH, and a test set from TESTSET_PATH in order to make
    predictions on it and run the metrics.

    It then saves the predictions in PREDICTIONS_PATH and the metrics report in
    REPORT_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading model from {}'.format(model_path))
    logger.info('reading feature extractor pipeline from {}'.format(
        feature_extractor_path))
    logger.info('reading test dataset from {}'.format(testset_path))
    logger.info('saving predictions in {}'.format(predictions_path))
    logger.info('saving report in {}'.format(report_path))
