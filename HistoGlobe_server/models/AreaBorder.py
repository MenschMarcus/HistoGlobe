# ==============================================================================
# The AreaBorder stores the spatial dimension of an Area. It represents one
# atmic closed borderline, geometrically a Polyline.
#
# ------------------------------------------------------------------------------
# AreaTerritory n:1 Area
#
# ==============================================================================


from django.db import models
from django.contrib import gis
from djgeojson.fields import *
from django.forms.models import model_to_dict

# ==============================================================================
class AreaBorder(models.Model):

  # superordinate: Area
  area =          models.ForeignKey(
                    'Area', related_name='border_of_area', default='0')

  ## borderline as polyline / linestring
  borderline =    gis.db.models.LineStringField (default='LINESTRING EMPTY')

  ## coastline (yes) or interior (no) border
  is_coastline =  models.BooleanField           (default=True)

  ## how certainly is this border accurate? in range ]0 .. 1]
  ## 1 = absolutely certain, 0 = absolutely uncertain
  certainty =     models.FloatField             (default=1.0)

  # overriding the default manager with a GeoManager instance.
  # didn't quite understand what this is for...
  objects =       gis.db.models.GeoManager      ()


  # ============================================================================
  def __unicode__(self):
    return str(self.id)

  # ============================================================================
  # check if certainty level is in range ]0 .. 1] and correct to 1
  # ============================================================================

  def check_certainty(self):
    if not ((self.certainty > 0.0) and (self.certainty <= 1.0)):
      self.certainty = 1.0

  # ============================================================================
  class Meta:
    app_label = 'HistoGlobe_server'
