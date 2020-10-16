I18n.backend.store_translations(:en, YAML.safe_load(<<-YML))
  dummy:
    confirm:
      confirm_key: 'Confirm key'
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
    action:
      dummy:
        key: 'Just example key'
    dummy_action:
      dummy:
        key: 'Another example key'
        result:
          result_key: 'Result key'
YML
