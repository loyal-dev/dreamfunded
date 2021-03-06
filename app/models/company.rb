class Company < ActiveRecord::Base

  def self.all_accredited
    all.order(:position).where(hidden: false, accredited: true).where.not(status: 3)
  end

  def self.all_funded
    all.order(:position).where(hidden: false, accredited: true, status: 3)
  end

  extend FriendlyId
  friendly_id :name, use: :slugged


  has_many :users



  has_many :investments

  has_many :sections
  has_many :comments
  has_many :bids
  has_many :founders
  accepts_nested_attributes_for :founders, reject_if: :all_blank, allow_destroy: true
  has_many :documents
  accepts_nested_attributes_for :documents, reject_if: :all_blank, allow_destroy: true
  has_many :liquidate_shares

  has_many :docusigns
  has_one :campaign
  has_many :general_infos
  has_one :financial_detail
  accepts_nested_attributes_for :financial_detail
  accepts_nested_attributes_for :campaign

  has_attached_file :image,
    :styles =>{
      },
    :storage => :s3,
    :bucket => 'dreamfunded',
    :path => "companies/:filename",
    :url =>':s3_domain_url',
    :s3_protocol => :https,
    :s3_credentials => {
      :access_key_id => "AKIAJWDE6UJS56MXQYPQ",
      :secret_access_key => "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"
    }

  has_attached_file :document,
    :storage => :s3,
    :bucket => 'dreamfunded',
    :path => "documents/:filename",
    :url =>':s3_domain_url',
    :s3_credentials => {
      :access_key_id => "AKIAJWDE6UJS56MXQYPQ",
      :secret_access_key => "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"
    }

  has_attached_file :cover,
    :styles =>{
      small: "360x",
      large: "900x"
      },
    :storage => :s3,
    :bucket => 'dreamfunded',
    :path => "cover-photos/:filename",
    :url =>':s3_domain_url',
    :s3_protocol => :https,
    :s3_credentials => {
      :access_key_id => "AKIAJWDE6UJS56MXQYPQ",
      :secret_access_key => "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"
    }

  validates_attachment_size :cover, :less_than => 5.megabytes
  validates_attachment_size :image, :less_than => 5.megabytes
   validates_attachment_content_type :cover, content_type: /\Aimage\/.*\z/
  validates_attachment_content_type :image, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]
  validates :goal_amount, numericality: { less_than_or_equal_to: 1000000 }
  validates_attachment_content_type :document, :content_type =>['application/pdf']


  def self.Status
		{
			:Coming_Soon => 1,
			:Active => 2,
			:Funded => 3,
		}
	end

  before_create do
    self.end_date = Date.today unless self.end_date
  end

	def get_status
		if self.status == 1
			"Coming Soon"
		elsif self.status == 2
			"Active"
		elsif self.status == 3
			"Funded"
		end
	end

	def total_shares
		 liquidate_shares.pluck(:number_shares).sum
	end

  def average_share_price
    if total_shares > 0
     liquidate_shares.pluck(:shares_price, :number_shares).map!{|a| a[0]*a[1]}.sum / liquidate_shares.pluck(:number_shares).sum
    end
  end

  def left_days
    if end_date == nil
      return ' '
    end
    days_left = (end_date -  Date.today).to_i
    days_left = ' ' if days_left <= 0
    days_left
  end

  def invested
    investments.pluck(:invested_amount).sum
  end

  def fund_america_invested_amount
    if !self.fund_america_code.empty?
        offering_code = self.fund_america_code.split(':').second
        begin
         p "PULLING FundAmerica API"
         p offering_code
          offering = FundAmerica::Offering.details(offering_code)
          return  offering["funds_in_escrow"]
        rescue JSON::ParserError => e
          puts e
          puts 'ERROR'
          return 'TBA'
        rescue FundAmerica::Error => e
          # Print response from FundAmerica API in case of unsuccessful response
          puts e.parsed_response
        else
          invested_amount
        end
    else
        invested_amount
    end
  end
end
