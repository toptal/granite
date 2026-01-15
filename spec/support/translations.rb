I18n.backend.store_translations(:en, YAML.safe_load(<<-YAML))
  dummy:
    other_key: 'dummy projector other key'
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
              wrong_author: 'George Orwell is the only acceptable author, %<author_name>s is not'
        embedded_action:
          attributes:
            base:
              embedded_not_passed: Embedded Not Passed
    dummy_action:
      key: 'dummy action key'
      dummy:
        key: 'dummy action dummy projector key'
        result:
          key: 'dummy action dummy projector result key'
YAML
