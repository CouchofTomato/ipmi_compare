class UpdateWizardProgressUniqueIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :wizard_progresses, name: "index_wizard_progresses_on_type_and_subject"

    add_index :wizard_progresses,
              [ :wizard_type, :subject_type, :subject_id, :user_id ],
              unique: true,
              name: "index_wizard_progresses_on_type_subject_and_user",
              where: "subject_id IS NOT NULL"
  end
end
