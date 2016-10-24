# ==============================================================================
# The AreaName stores the attribute dimension (name) of an Area
# - short name,    e.g. 'Germany'
# - formal name,   e.g. 'Federal Republic of Germany"
#
# ------------------------------------------------------------------------------
# AreaName n:1 Area
# AreaName 1:1 OldArea
# AreaName 1:1 NewArea
# AreaName 2:2 UpdateArea
#
# ------------------------------------------------------------------------------
# TODO: currently only English -> to be extended
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class AreaName(models.Model):

  # superordinate: Area
  area =                  models.ForeignKey         ('Area',   related_name='name_area', default='0')

  # own attributes
  short_name =            models.CharField          (max_length=100, default='')
  formal_name =           models.CharField          (max_length=150, default='')

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return str(self.short_name)

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'