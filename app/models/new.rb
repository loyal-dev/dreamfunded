class New < ActiveRecord::Base
	validates :title, presence:true
	validates :image_filename, presence:true
	validates :content, presence:true
	validates :source, presence:true
end