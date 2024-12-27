# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Fits and saves feature extractors.')
@click.argument('dataset_path', type=click.Path(exists=True))
@click.argument('feature_extractor_path', type=click.Path())
def build_features(dataset_path, feature_extractor_path):
    """Fits and saves feature extractors.

    Reads a dataset from DATASET_PATH, runs the feature extractor
    pipeline and saves it in FEATURE_EXTRACTOR_PATH for future use.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading dataset from {}'.format(dataset_path))
    logger.info('saving feature extractor pipeline in {}'.format(
        feature_extractor_path))
