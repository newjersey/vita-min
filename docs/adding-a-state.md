# Adding a new state to directfile

## Add a new intake model and corresponding db table
- Generate a migration called `CreateStateFile[state abbreviation]Intakes`
- Generate a model from the migration
- When you run the migration, it will annotate the model and add spec files

## Add state data to state information service
- Add an entry for your state in `STATES_INFO` in `app/services/state_file/state_information_service.rb`. Add the intake model you created under intake_class
- Also create files for:
  - Navigation class (`app/lib/navigation/state_file_[state abbreviation]_question_navigation.rb`)
  - Calculator class
  - Submission builder class

## Include your state in multi tenant service
- Under `SERVICE_TYPES` IN `app/services/multi_tenant_service.rb`, add your state. In the same file, add a when clause for navigation

## Add your state to the routes file
- In `config/routes.rb`, add a `devise_for` line
- In the same file, add our state abbreviation to the `scope ':us_state'` lines where other states are listed
- In the same file, add `scoped_navigation_routes` for the question navigation

## Add state-specific styles
- Add your state logo under `app/assets/images/partner-logos`, naming it `[state abbreviation]gov-logo.svg`
- Add your state color under app/assets/stylesheets/_variables.scss, naming it `$color-[state abbreviation]-[color name]`

## Add a new navigation class
- In the navigation class you added in `app/lib/navigation`

## Build XML submission builder class and any document builders

## Add PDF builder for above doc types and corresponding fillable PDFs

## Edit content
- Add translated text for your state to `config/locales/[lang].yml` files as needed to get the app running
- Edit content in `app/views/state_file/questions/eligible/edit.html.erb`