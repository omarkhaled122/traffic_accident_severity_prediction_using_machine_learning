# -*- coding: utf-8 -*-
import logging

import click


@click.command(short_help='Exploratory oriented visualizations.')
@click.argument('dataset_path', type=click.Path(exists=True))
@click.argument('report_path', type=click.Path())
def visualize_data(dataset_path, report_path):
    """Creates exploratory oriented visualizations.

    Reads a dataset from DATASET_PATH, creates exploratory
    visualizations and saves them in REPORT_PATH.
    """
    logger = logging.getLogger(__name__)
    logger.info('reading dataset from {}'.format(dataset_path))
    logger.info('saving report in {}'.format(report_path))
