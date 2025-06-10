class CreateJobLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :job_languages do |t|
      t.references :job, null: false, foreign_key: true
      t.references :language, null: false, foreign_key: true

      t.timestamps
    end
  end
end
