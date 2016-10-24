# ==============================================================================
# The AreaTerritory stores the spatial dimension of an Area
# - the geometry as a Polypolygon (MultiPolygon)
# - the representative point of the territory (Point)
#
# ------------------------------------------------------------------------------
# AreaTerritory n:1 Area
# AreaTerritory 1:1 OldArea
# AreaTerritory 1:1 NewArea
# AreaTerritory 2:2 UpdateArea
#
# ------------------------------------------------------------------------------
# TODO: calculate reasonable name position with intelligent algorithm
# ==============================================================================


from django.db import models
from django.contrib import gis
from djgeojson.fields import *
from django.forms.models import model_to_dict

# ==============================================================================
class AreaTerritory(models.Model):

  # superordinate: Area
  area =                  models.ForeignKey               ('Area',   related_name='territory_area', default='0')

  # own attributes
  geometry =              gis.db.models.MultiPolygonField (default='MULTIPOLYGON EMPTY')
  representative_point =  gis.db.models.PointField        (null=True)

  # overriding the default manager with a GeoManager instance.
  # didn't quite understand what this is for...
  objects =               gis.db.models.GeoManager        ()

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return str(self.id)


  # ----------------------------------------------------------------------------
  # make territory ready to output (use wkt string of geometry)
  # ----------------------------------------------------------------------------

  def prepare_output(self):

    return({
      'id':                   self.id,
      'area':                 self.area.id,
      'representative_point': self.representative_point.wkt,
      'geometry':             self.geometry.wkt
    })


  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'