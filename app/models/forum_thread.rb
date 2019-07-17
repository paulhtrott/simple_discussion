class ForumThread < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged

  has_paper_trail


  #belongs_to :forum_category
  belongs_to :category
  belongs_to :user
  belongs_to :last_changed_by, class_name: 'User', optional: true
  has_many :forum_posts
  has_many :forum_subscriptions
  has_many :optin_subscribers,  ->{ where(forum_subscriptions: { subscription_type: :optin }) },  through: :forum_subscriptions, source: :user
  has_many :optout_subscribers, ->{ where(forum_subscriptions: { subscription_type: :optout }) }, through: :forum_subscriptions, source: :user
  has_many :users, through: :forum_posts

  has_many :flagged_items, as: :flaggable

  has_many :likes, as: :likeable

  accepts_nested_attributes_for :forum_posts

  #validates :forum_category, presence: true
  validates :category, presence: true
  validates :user_id, :title, presence: true
  validates_associated :forum_posts

  scope :pinned_first, ->{ order(pinned: :desc) }
  scope :solved,       ->{ where(solved: true) }
  scope :sorted,       ->{ order(updated_at: :desc) }
  scope :unpinned,     ->{ where.not(pinned: true) }
  scope :unsolved,     ->{ where.not(solved: true) }
  scope :not_flagged,  ->{ where.not(id: FlaggedItem.where(flaggable_type: 'ForumThread', aasm_state: 'keep').pluck(:flaggable_id)) }

  def parent
    self
  end

  def subscribed_users
    (users + optin_subscribers).uniq - optout_subscribers
  end

  def subscription_for(user)
    return nil if user.nil?
    forum_subscriptions.find_by(user_id: user.id)
  end

  def subscribed?(user)
    return false if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      subscription.subscription_type == "optin"
    else
      forum_posts.where(user_id: user.id).any?
    end
  end

  def toggle_subscription(user)
    subscription = subscription_for(user)

    if subscription.present?
      subscription.toggle!
    elsif forum_posts.where(user_id: user.id).any?
      forum_subscriptions.create(user: user, subscription_type: "optout")
    else
      forum_subscriptions.create(user: user, subscription_type: "optin")
    end
  end

  def subscribed_reason(user)
    #return "Follow this topic to be notified when there are new posts." if user.nil?
    return I18n.t :no_user, scope: [:simple_discussion, :thread_messages] if user.nil?

    subscription = subscription_for(user)

    if subscription.present?
      if subscription.subscription_type == "optout"
        I18n.t :optout, scope: [:simple_discussion, :thread_messages]
      elsif subscription.subscription_type == "optin"
        I18n.t :optin, scope: [:simple_discussion, :thread_messages]
      end
    elsif forum_posts.where(user_id: user.id).any?
      I18n.t :notified, scope: [:simple_discussion, :thread_messages]
    else
      I18n.t :not_notified, scope: [:simple_discussion, :thread_messages]
    end
  end

  # These are the users to notify on a new thread. Currently this does nothing,
  # but you can override this to provide whatever functionality you like here.
  #
  # For example: You might use this to send all moderators an email of new threads.
  def notify_users
    []
  end

  def name
    "Forum (#{title})"
  end

  def body
    forum_posts.first.body
  end
end
