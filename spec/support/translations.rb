I18n.backend.store_translations(:en, YAML.safe_load(<<-YML))
  granite_action:
    errors:
      messages:
        action_invalid: "Name can't be blank"
      models:
        action:
          attributes:
            base:
              message: 'Base error message'
              wrong_title: 'Wrong title'
YML
