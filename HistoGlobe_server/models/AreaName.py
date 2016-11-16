# ==============================================================================
# The AreaName stores an attribute dimension "name" of an Area
# (short and formal name)
#
# ------------------------------------------------------------------------------
# AreaName n:1 Area
#
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class AreaName(models.Model):

  # superordinate: Area
  area =        models.ForeignKey ('Area', related_name='name_area', default='0')

  # own attributes
  # TODO: currently only English -> to be extended / replaced by Multilang
  # object which saves the name in different languages.

  ## short name,    e.g. 'Germany'
  short_name =  models.CharField  (max_length=100, default='')

  ## formal name,   e.g. 'Federal Republic of Germany".
  formal_name = models.CharField  (max_length=150, default='')


  # ============================================================================
  def __unicode__(self):
    return str(self.short_name)

  # ============================================================================
  class Meta:
    app_label = 'HistoGlobe_server'
