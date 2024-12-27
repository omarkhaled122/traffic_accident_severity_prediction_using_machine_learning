# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Trains a model')
@click.argument('dataset_path', type=click.Path(exists=True))
@click.argument('feature_extractor_path', type=click.Path(exists=True))
@click.argument('model_path', type=click.Path())
def train_model(dataset_path, feature_extractor_path, model_path):
    """Trains a model.

    Reads a dataset from DATASET_PATH, a feature extractor pipeline from
    FEATURE_EXTRACTOR_PATH, trains a model and saves it in MODEL_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading dataset from {}'.format(dataset_path))
    logger.info('reading feature extractor pipeline from {}'.format(
        feature_extractor_path))
    logger.info('saving model in {}'.format(model_path))
