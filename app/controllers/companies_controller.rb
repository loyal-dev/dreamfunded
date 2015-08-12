class CompaniesController < ApplicationController
	#Default site that shows all startups
	def index
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Basic]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
		@companies = Company.all
	end
	
	def new
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Founder]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
	end

	#Creates a new startup profile (Need to implement session for later)
	def create
		if params[:file] != nil
			uploaded_file = params[:file]
			@file_name = uploaded_file.original_filename
			directory = "app/assets/images/companies/"
			path = File.join(directory, @file_name)
			File.open(path, "wb") { |f| f.write(uploaded_file.read) }

			@user_id = session[:current_user].login
			@name = params[:name]
			@description = params[:description][0]
			@goal = params[:goal]
			@status = params[:status]
			@invested = 0
			@weblink = ""
			@videolink = ""
			@ceo = params[:CEO]
			@number = params[:CEO_number]
			@display = 0

			if params[:amount]
				@invested = params[:amount]
			end

			if params[:url]
				@weblink = params[:url]
			end

			if params[:video]
				@videolink = params[:video]
			end

			uploaded = Company.new(:user_id => @user_id, :name => @name, :description => @description, :image_file_name => @file_name,
				:goal_amount => @goal, :status => @status, :invested_amount => @invested, :website_link => @weblink, :video_link => @videolink, 
				:CEO => @ceo, :CEO_number => @number, :display => @display, :days_left => 10)

			if uploaded.valid?
				uploaded.save
				redirect_to "/companies"
			else
				@error_message = ""
				uploaded.errors.full_messages.each do |error|
					@error_message = @error_message + error + ". "
				end
				flash[:message] = @error_message
				redirect_to "/companies/new"
			end
		else
			flash[:message] = "Image is not valid"
			redirect_to "/companies/new"
		end
	end

	def edit
		@companies = Company.all
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Founder]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
	end

	def action
		@my_company = Company.find_by(id: params[:id])

		if @my_company == nil
			@message = ""
			@message = "No company with that ID exists. Please create the company first."
			flash[:fail] = @message
			redirect_to url_for(:controller => 'companies', :action => 'edit')
		elsif params[:id] != nil && params[:desired_action] == "1"
			redirect_to url_for(:controller => 'companies', :action => 'make_team', :id => params[:id])

		elsif params[:id] != nil && params[:desired_action] == "2"
			redirect_to url_for(:controller => 'companies', :action => 'make_profile', :id => params[:id])
		end
	end

	def make_team
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Founder]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
	end

	def add_team_member
		@id = params[:id]
		if params[:file1] != nil
			uploaded_file = params[:file1]

			@file_name = uploaded_file.original_filename

			directory = "app/assets/images/companies/"
			path = File.join(directory, @file_name)

			File.open(path, "wb") { |f| f.write(uploaded_file.read) }

			@name = params[:name1]
			@content = params[:content1][0]
			@position = params[:position]
			@comp_id = params[:id]
			founder1 = Founder.new(:name => @name, :position => @position, :image_address => @file_name, :content => @content, :company_id => @comp_id)

			if founder1.valid?
				founder1.save
				redirect_to "/companies"
			else
				@error_message2 = ""
				founder1.errors.full_messages.each do |error|
					@error_message2 = @error_message2 + error + ". "
				end

				flash[:notice] = @error_message2
				redirect_to "/companies/make_team"
			end
		else
			flash[:notice] = "Image is not valid"
			redirect_to "/companies/make_team"
		end
	end

	def make_profile
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Founder]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
	end

	def submit_profile
		@id = params[:id]
		@overview = params[:overview][0]
		@tm = params[:target_market][0]
		@cid = params[:current_investor_details][0]
		@dm = params[:detailed_metrics][0]
		@ct = params[:customer_testimonials][0]
		@cl = params[:competitive_landscape][0]
		@use = params[:planned_use_of_funds][0]
		@pitch = params[:pitch_deck][0]

		section = Section.new(:id => @id, :overview => @overview, :target_market => @tm, :current_investor_details => @cid, :detailed_metrics => @dm, :customer_testimonials => @ct, :competitive_landscape => @cl, :planned_use_of_funds => @use, :pitch_deck => @pitch)
		
		if section.valid?
			section.save!
			redirect_to "/companies"
		else
			@error_message3 = ""
			section.errors.full_messages.each do |error|
				@error_message3 = @error_message3 + error + ". "
			end
			flash[:problem] = @error_message3
			redirect_to "/companies/make_profile"
		end
	end

	def company_profile
		if params[:id] != nil
			@id = params[:id]
			@company = Company.find(params[:id])
			@progress = @company.invested_amount / @company.goal_amount rescue 0

			@members = Founder.where(company_id: params[:id])
			@section = Section.find_by(id: params[:id])
		else
			redirect_to "/companies"
		end
	end

	def edit_profile
		if session[:current_user] == nil || session[:current_user].authority < User.Authority[:Admin]
			redirect_to url_for(:controller => 'home', :action => 'unauthorized')
		end
		@company = Company.find(params[:id])
	end

	def update
		updated = Company.new(:name => params[:name], :website_link => params[:website_link], :invested_amount => params[:invested_amount], :days_left => params[:days_left])
		if updated.valid?
			updated.save!
			redirect_to :controller => 'companies', :action => 'company_profile', :id => params[:id]
		else
			@error_update = ""
			updated.errors.full_messages.each do |error|
				@error_update = @error_update + error + ". "
			end
			flash[:problem_update] = @error_update
			redirect_to :controller => 'companies', :action => 'edit_profile', :id => params[:id]
		end
	end

	def remove_company
		if params[:id] != nil
	    	@company = Company.find(params[:id])
	    	if (@company != nil) 
	    		@company.destroy
	    	end
	    end
    	
    	redirect_to "/companies"
    end

    def remove_founder
		if params[:id] != nil
	    	@founder = Founder.find(params[:id])
	    	if @founder!= nil
	    		@founder.destroy
	    	end
	    end

	    redirect_to "/companies"
    end

    def approve_company
		if params[:id] != nil
	    	@company = Company.find(params[:id])
	    	if @company != nil 
	    		@company.update_column :display, 1
	    	end
	    end
    	
    	redirect_to "/companies"
    end
end
