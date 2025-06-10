class JobsQuery
  def initialize(params = {}, scope = Job.all)
    @params = params
    # Eager load associations to prevent N+1 queries in serialization
    @scope = scope.includes(:languages, :shifts)
  end

  def call
    apply_filters
    @scope
  end

  private

  def apply_filters
    # Filter by title
    if @params[:title].present?
      @scope = @scope.where("title ILIKE ?", "%#{@params[:title]}%")
    end

    # Filter by language
    if @params[:language].present?
      @scope = @scope.joins(:languages).where("languages.name ILIKE ?", "%#{@params[:language]}%").distinct
    end

    # Add more filters here as the application grows, adhering to OCP
    # Example:
    # if @params[:min_salary].present?
    #   @scope = @scope.where("hourly_salary >= ?", @params[:min_salary])
    # end
  end
end
