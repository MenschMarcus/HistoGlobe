# ==============================================================================
# An HiventOperation actually changes the Areas and their AreaNames/Territories
# on the map. Each HiventOperation is part of exactly one EditOperation.
# To this HiventOperation will be referenced:
#   - A set of OldAreas with AreaNames and AreaTerritories that are deleted
#   - An UpdateArea with the changing AreaName / AreaTerritory
#   - A set of NewAreas with AreaNames and AreaTerritories that are created
#
# ------------------------------------------------------------------------------
# HiventOperation n:1 EditOperation
# HiventOperation 1:n OldArea
# HiventOperation 1:n NewArea
# HiventOperation 1:1 UpdateArea
#
# ------------------------------------------------------------------------------
# Hivent Operations
#
#      UNI             INC             SEP             SEC             NCH
#  Unification    Incorporation     Separation      Secession       Name Change
#
# Ai ---|         A0 ---O--- A0         |--- Bi   A0 ---O--- A0   A0 ---O--- A0
# ..    O--- B1   Ai ---|         A1 ---O    ..         |--- Bi
# An ---|         An ---|               |--- Bn         |--- Bn
# ==============================================================================


from django.db import models
from django.forms.models import model_to_dict

# ==============================================================================
class HiventOperation(models.Model):

  # superordinate: EditOperation
  edit_operation   = models.ForeignKey ('EditOperation', related_name='edit_operation', default=0)

  # own attribute
  operation        = models.CharField  (default='XXX', max_length=3)

  # ----------------------------------------------------------------------------
  def __unicode__(self):
    return self.operation

  # ----------------------------------------------------------------------------
  class Meta:
    app_label = 'HistoGlobe_server'