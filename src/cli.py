#!/usr/bin/env python
# -*- coding: utf-8 -*-
import logging
import os
import sys

import click
from dotenv import find_dotenv, load_dotenv

from data.make_dataset import make_dataset
from data.split_dataset import split_dataset
from features.build_features import build_features
from models.predict import predict, test_model
from models.train_model import train_model
from visualization.visualize import visualize_data


@click.group(context_settings={'help_option_names': ['-h', '--help']})
@click.option(
    '-v', '--verbose', default=False, is_flag=True, help='Print more logs.')
@click.pass_context
def cli(ctx, verbose):
    """Command line interface to Traffic Accident Severity Prediction Using Machine Learning."""
    ctx.obj['verbose'] = verbose

    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    log_lvl = logging.INFO if verbose else logging.WARN
    logging.basicConfig(level=log_lvl, format=log_fmt)


cli.add_command(make_dataset)
cli.add_command(split_dataset)
cli.add_command(build_features)
cli.add_command(predict)
cli.add_command(train_model)
cli.add_command(test_model)
cli.add_command(visualize_data)


def load_config():
    dotenv_path = find_dotenv(filename='.env')
    if dotenv_path != '':
        load_dotenv(dotenv_path)  # load secrets
    load_dotenv(find_dotenv(filename='config'))  # load config
    project_dir = os.path.join(os.path.dirname(__file__))
    sys.path.append(project_dir)
    cli(obj={})


if __name__ == '__main__':
    load_config()
