class CreateElements < ActiveRecord::Migration
  def change
    create_table :elements do |t|
      t.string :address
      t.string :title
      t.string :summary
      t.string  :content
    end

    add_index :elements, :address, unique: true
  end
end
