from django.conf.urls import url, include, patterns
from django.contrib.gis import admin
from HistoGlobe_server import views

urlpatterns = [
  url(r'^$',                    views.index,                name='index'),

  url(r'^get_all/',             views.get_all,              name="get_all"),
  url(r'^save_operation/',      views.save_operation,       name="save_operation"),

  url(r'^admin/',               include(admin.site.urls))
]
