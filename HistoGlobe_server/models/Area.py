# ==============================================================================
# An Area represents a political entitry (e.g. country, state, province,
# overseas territory, ...) with a specific identity in history. It has a name
# and a geometry attached to at any givent point in history. Additionally, it is
# hierarchically related to other Areas (superordinate / subordinate) and can
# have a certain status (e.g. unclaimed land, water, ...).
#
# ------------------------------------------------------------------------------
# Area 1:n AreaRelation
# Area 1:n AreaName
# Area 1:n AreaTerritory
# Area 2:n AreaBorder
#
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class Area(models.Model):

  # own attributes

  ## There is one and only one universe Area which is initially and always
  ## active in the spatio-temporal system. It is the root node of the historical
  ## hierarchical tree of Areas in the system.
  universe =    models.BooleanField (default=False)

  ## An Area is land, if it is potentially habitated (historical/social unit).
  ## Otherwise it is considered as water.
  land =        models.BooleanField (default=True)

  ## The atomic land Areas of the hierarchy (Areas without subordinates) own a
  ## geometry in form of a set of borders forming a polypolygon.
  atomic =      models.BooleanField (default=True)

  ## An Area that is land but not habitated is unclaimed.
  unclaimed =   models.BooleanField (default=False)

  ## An Area that is land, potentially habitated but does not belong to a
  ## sovereign country, can be implemented as a neutral zone.
  neutral =     models.BooleanField (default=False)

  ## A contestet Area is a land Area that is claimed by more than one sovereign
  ## country
  contested =   models.BooleanField (default=False)


  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return str(self.id)

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'
