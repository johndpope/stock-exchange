class GannAngle
  attr_reader :days_before_startpoint, :a_b_min_window
  attr_reader :start_point, :end_point
  attr_reader :point_a, :point_b
  attr_reader :alpha, :beta, :gamma
  attr_reader :angles

  def initialize(points)
    @points = points
  end

  def run(days_before_startpoint, a_b_min_window)
    @days_before_startpoint = days_before_startpoint
    @a_b_min_window = a_b_min_window
    @angles = {}

    reset

    points.each do |p|
      # 1. Select point where the 20 period moving average crosses below the 50 period
      unless find_start_point(p)
        # 2. Find highest high within the 60 days before p1 and mark point A
        @point_a = find_highest

        unless find_end_point(p)
          # 3. Lowest low point between p1 and p2, mark as B
          @point_b = lowest(points[start_point.position..end_point.position])

          # 4. Test that B - A > 90 days, ignore if not
          if point_b.position - point_a.position < a_b_min_window
            reset
          else
            # 5. Calculate price difference between A and B
            @alpha, @beta, @gamma, x = calc_price_diff
            @angles[start_point] = {alpha: alpha, beta: beta, gamma: gamma, x: x.round}
            reset
          end
        end
      end
    end
  end

  private

  ANGLES = [
    100.0, # Alpha (y / x)
    61.8,  # Beta (y * 0.618) / x
    38.2,  # Gamma (y * 0.382) / x
    50.0,  # Mid (y * 0.5) / x
    76.4,
    23.6   # Low (y * 0.236) / x
  ]

  attr_reader :points

  def reset
    @finding_start_point = true
    @finding_end_point = true
  end

  def find_start_point(p)
    if @finding_start_point && p.mov_avg_20d <= p.mov_avg_50d
      @start_point = p
      @finding_start_point = false
    end
    @finding_start_point
  end

  def find_end_point(p)
    if @finding_end_point && p.mov_avg_20d > p.mov_avg_50d
      @end_point = p
      @finding_end_point = false
    end
    @finding_end_point
  end

  def find_highest
    from = start_point.position - days_before_startpoint
    from = 0 if from <= 0
    points[from...start_point.position].
      sort { |p, o| [p.date, p.px_high] <=> [o.date, o.px_high] }.
      first
  end

  def lowest(points)
    points.sort_by!(&:px_low).first
  end

  def calc_price_diff
    # 5. Calculate price difference between A and B, call this “y”
    y = point_a.px_high.to_f - point_b.px_low.to_f
    # 6. Calculate number of trading days between A and B, call this “x”
    x = point_b.position.to_f - point_a.position.to_f

    res = []

    ANGLES.each do |angle|
      res << y * (angle / 100.0) / x
    end

    res << x

    if false
      CSV.open("file.csv", "wb") do |csv|
        points.each do |p|
          csv << [
            p.chart_date,
            p.position,
            p.mov_avg_50d,
            p.mov_avg_20d,
            p.px_high,
            p.px_low]
        end
      end
    end

    res
  end
end
