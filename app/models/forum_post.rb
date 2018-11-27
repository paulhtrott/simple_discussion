class ForumPost < ApplicationRecord
  belongs_to :forum_thread, counter_cache: true, touch: true
  belongs_to :user
  #has_many :reactions, as: :reactable # not sure this is used anywhere, seems to break ability to soft delete

  has_many :likes, as: :likeable

  validates :user_id, :body, presence: true

  scope :sorted, ->{ order(:created_at) }

  after_update :solve_forum_thread, if: :solved?

  def solve_forum_thread
    forum_thread.update(solved: true)
  end
end
