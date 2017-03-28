{% from "salt/map.jinja" import salt_settings with context %}

salt-minion:
{% if salt_settings.install_packages %}
  pkg.installed:
    - name: {{ salt_settings.salt_minion }}
    - order: last
{%- if salt_settings.salt_minion_version %}
    - version: {{ salt_settings.salt_minion_version }}
{%- endif %}
    - refresh: true
{% elif grains['os_family'] in ('AIX','Windows') %}
  archive.extracted:
    - name: {{ salt_settings.minion_install_path }}
    - source: {{ salt_settings.minion_installer }}
    - source_hash: {{ salt_settings.minion_installer_hash }}
    - archive_format: {{ salt_settings.archive_format }} 
    - enforce_toplevel: false
  cmd.run:
    - name: {{ salt_settings.minion_install_cmd }}
    - cwd: {{ salt_settings.minion_install_path }}
    - shell: {{ salt_settings.minion_install_shell }}
{% endif %}
  file.recurse:
    - name: {{ salt_settings.config_path }}/minion.d
    - template: jinja
    - source: salt://{{ slspath }}/files/minion.d
    - clean: {{ salt_settings.clean_config_d_dir }}
    - exclude_pat: _*
    - context:
        standalone: False
{% if grains['os_family'] not in ('AIX', 'Windows') %}
  service.running:
    - enable: True
    - name: {{ salt_settings.minion_service }}
    - watch:
{% if salt_settings.install_packages %}
      - pkg: salt-minion
{% endif %}
      - file: salt-minion
      - file: remove-old-minion-conf-file
{% endif %}

{%- if grains['os_family'] == 'AIX' %}
restart-salt-minion:
  cmd.wait:
    - name: echo '{{ salt_settings.minion_service }} stop && {{ salt_settings.minion_service }} start' | at now + 1 minute
    - order: last
    - watch:
      - archive: salt-minion
      - file: remove-old-minion-conf-file
{% endif %}

# clean up old _defaults.conf file if they have it around
remove-old-minion-conf-file:
  file.absent:
    - name: /etc/salt/minion.d/_defaults.conf
