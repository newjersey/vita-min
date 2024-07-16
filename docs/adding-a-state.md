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

## Add your state to the routes file
- In `config/routes.rb`, add a `devise_for` line
- In the same file, add our state abbreviation to the `scope ':us_state'` lines where other states are listed
- In the same file, add `scoped_navigation_routes` for the question navigation

## Add state-specific styles
- Add your state logo under `app/assets/images/partner-logos`, naming it `[state abbreviation]gov-logo.svg`
- Add your state color under app/assets/stylesheets/_variables.scss, naming it `$color-[state abbreviation]-[color name]`

## Add a new navigation class
- In the navigation class you added in `app/lib/navigation`, create sections including:
  - The landing page controller
  - Eligibility
  - Contact info
  - Terms and conditions
  - Data transfer
  - Sections for state-specific questions
  - Esign
  - Form submission

## Add a question
- Make sure the value is included in the database and the model
- Create a controller for the question under `app/controllers/state_file/questions` (the controller name will determine the name of the route)
- Add that controller to a section (or create a section) in the navigation class you created
- Create a form for the question under `app/forms/state_file`
- Create a view for the question under `app/views/state_file/questions`
- Add text for the question under `config/locales`

## Build XML submission builder class and any document builders
If you do have access to the CfA folder where schemas are kept, run the rake tasks `download_efile_schemas` and `unzip_efile_schemas`. (THis has already been taken care if you ran the setup script and it worked.)

If you do not but you have a zip file of schema data for your state:
- Try adding the zip file to `vendor/us_states` and then running the rake task
- Alternatively, just add the unzipped files to `vendor/us_states_unpacked`

The folder `unpacked` is excluded from version control.

Then, for each tax form you support:
- Add a calculator class: `app/lib/efile/[state abbreviation]/[form name].rb`
- Add a submission builder: `app/lib/submission_builder/ty[tax year]/states/[state_abbreviation]/documents/[form name].rb`

## Add PDF builder for above doc types and corresponding fillable PDFs
Add a pdf filler: `app/lib/pdf_filler/[form name]_pdf.rb`

## Edit content
- Add translated text for your state to `config/locales/[lang].yml` files as needed to get the app running
- Edit content in `app/views/state_file/questions/eligible/edit.html.erb`

## Add fake return data
- Create a folder for your state under `spec/fixtures/state_file/fed_return_xmls/[year]`
- Create fake xml data
- You can select this data at the fake data transfer step
