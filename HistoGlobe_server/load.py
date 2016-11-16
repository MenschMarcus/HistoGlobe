"""
  This file does all the initialization work for the database:
  - create inital set of Areas of Europe in in year 2015.

  Caution: This can be performed ONLY in the beginning, when it is clear that
  all areas in the database are actually active in 2015. As soon as the first
  historical country is added, this script is not usable anymore.
"""

# ==============================================================================
# INCLUDES
# ==============================================================================

# general python modules
import os
# import csv
import json
import iso8601      # for date string -> date object

# geo stuff
import pygeoj
from django.contrib.gis.geos import *

# own
import HistoGlobe_server
from models import *


# ------------------------------------------------------------------------------
def get_file(filename):
  return os.path.abspath(os.path.join(
      '/home/marcus/HistoGlobe/HistoGlobe/HistoGlobe_server/',
      'data/',
      filename
    )
  )


# ==============================================================================
# MAIN PROGRAM
# ==============================================================================

# idea: create hierarchical structure of Germany with geometry upwards

def run(verbose=True):

  # CLEANUP

  Area.objects.all().delete()
  print('All objects deleted from database')


  # INIT UNIVERSE (OMEGA)
  universe = Area(
      universe =    True,
      land =        False,
    )
  universe.save()

  ## border attachted to universe: spanning the whole world
  full_world_dimension = LineString(
      (-LNG_MAX, -LAT_MAX),
      (-LNG_MAX,  LAT_MAX),
      ( LNG_MAX,  LAT_MAX),
      ( LNG_MAX, -LAT_MAX),
      (-LNG_MAX, -LAT_MAX)
    )

  universe_border = AreaBorder(
      area =        universe,
      borderline =  full_world_dimension
    )
  universe_border.save()

  ## the universe has no name

  print("Universe Area created")


  # LOAD ALL FILES (DEU -> TODO: whole world)
  # access to data with pygeoj:
  # https://github.com/karimbahgat/PyGeoj

  deu0 = pygeoj.load(get_file('gadm_germany/DEU_adm0.geojson'))
  deu1 = pygeoj.load(get_file('gadm_germany/DEU_adm1.geojson'))
  deu2 = pygeoj.load(get_file('gadm_germany/DEU_adm2.geojson'))
  deu3 = pygeoj.load(get_file('gadm_germany/DEU_adm3.geojson'))
