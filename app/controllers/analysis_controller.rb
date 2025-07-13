class AnalysisController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def check_analysis_count
    # 개발 중이므로 무제한으로 설정
    render json: { 
      remaining_count: 999, 
      total_limit: 999 
    }
  end

  def analyze_image
    Rails.logger.info "=== AI 분석 요청 시작 ==="
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request parameters: #{params.keys}"
    Rails.logger.info "Session ID: #{session.id}"
    
    # 세션에서 분석 횟수 추적
    session[:analysis_count] ||= 0
    Rails.logger.info "Session analysis_count: #{session[:analysis_count]}"
    
    current_count = session[:analysis_count]
    Rails.logger.info "Current analysis count: #{current_count}"
    
    # 개발 중이므로 횟수 제한 주석 처리
    # if current_count >= 3
    #   render json: { error: "일일 분석 횟수를 초과했습니다. 내일 다시 시도해주세요." }, status: 429
    #   return
    # end

    image_data = params[:image]
    Rails.logger.info "Image data received: #{image_data.present? ? 'Yes' : 'No'}"
    
    if image_data.blank?
      Rails.logger.error "Image data is blank"
      render json: { error: "이미지 데이터가 없습니다." }, status: 400
      return
    end
    
    Rails.logger.info "Image data length: #{image_data.length}"
    
    # base64 데이터 추출
    if image_data.start_with?('data:image/')
      base64_data = image_data.split(',').last
      Rails.logger.info "Extracted base64 data, length: #{base64_data.length}"
    else
      base64_data = image_data
      Rails.logger.info "Using image data as is, length: #{base64_data.length}"
    end
    
    # Claude API 키 확인
    api_key = ENV['ANTHROPIC_API_KEY']
    Rails.logger.info "Claude API key present: #{api_key.present?}"
    
    if api_key.present?
      # 따옴표 제거 (환경 변수에서 따옴표가 포함된 경우)
      api_key = api_key.gsub(/^["']|["']$/, '')
      Rails.logger.info "Using Claude API key: #{api_key[0..10]}..."
      
      begin
        Rails.logger.info "Calling Claude API..."
        result = call_claude_api(base64_data, api_key)
        Rails.logger.info "Analysis completed successfully"
        
        # 분석 횟수 증가
        session[:analysis_count] = current_count + 1
        Rails.logger.info "Updated analysis count: #{session[:analysis_count]} (개발 모드 - 제한 없음)"
        
        render json: { 
          analysis: result, 
          remaining_count: 999, 
          total_limit: 999 
        }
      rescue => e
        Rails.logger.error "Claude API Error: #{e.class} - #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
        
        # 에러 발생 시 데모 응답 사용
        Rails.logger.info "Using demo response due to API error"
        demo_result = get_demo_response
        
        session[:analysis_count] = current_count + 1
        Rails.logger.info "Updated analysis count: #{session[:analysis_count]} (데모 응답)"
        
        render json: { 
          analysis: demo_result, 
          remaining_count: 999, 
          total_limit: 999 
        }
      end
    else
      Rails.logger.info "Claude API key not found, using demo response"
      demo_result = get_demo_response
      
      session[:analysis_count] = current_count + 1
      Rails.logger.info "Updated analysis count: #{session[:analysis_count]} (데모 응답)"
      
      render json: { 
        analysis: demo_result, 
        remaining_count: 999, 
        total_limit: 999 
      }
    end
    
    Rails.logger.info "=== AI 분석 요청 종료 ==="
  end

  private

  def call_claude_api(base64_data, api_key)
    Rails.logger.info "=== Claude API 호출 시작 ==="
    
    # 프롬프트 생성
    prompt = generate_prompt
    Rails.logger.info "Prompt generated, length: #{prompt.length}"
    Rails.logger.info "Image data length for API: #{base64_data.length}"
    
    # 이미지 미디어 타입 감지
    media_type = case base64_data[0..10]
    when /^\/9j/ then 'image/jpeg'
    when /^iVBORw0KGgo/ then 'image/png'
    when /^R0lGODlh/ then 'image/gif'
    when /^UklGRg/ then 'image/webp'
    else 'image/jpeg'
    end
    
    Rails.logger.info "Detected media type: #{media_type}"
    
    # HTTP 클라이언트 설정
    require 'net/http'
    require 'json'
    
    uri = URI('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    # 요청 헤더
    headers = {
      'Content-Type' => 'application/json',
      'x-api-key' => api_key,
      'anthropic-version' => '2023-06-01'
    }
    
    Rails.logger.info "Request headers prepared"
    
    # 요청 본문
    body = {
      model: 'claude-3-haiku-20240307',
      max_tokens: 1000,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: prompt
            },
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: media_type,
                data: base64_data
              }
            }
          ]
        }
      ]
    }
    
    Rails.logger.info "Request body prepared"
    Rails.logger.info "Model: claude-3-haiku-20240307"
    Rails.logger.info "Max tokens: 1000"
    Rails.logger.info "Sending request to Claude..."
    
    # 요청 전송
    request = Net::HTTP::Post.new(uri)
    headers.each { |key, value| request[key] = value }
    request.body = body.to_json
    
    Rails.logger.info "Request sent, waiting for response..."
    
    response = http.request(request)
    Rails.logger.info "Claude API response received"
    Rails.logger.info "Response status: #{response.code}"
    
    if response.code == '200'
      response_data = JSON.parse(response.body)
      Rails.logger.info "Response keys: #{response_data.keys}"
      
      content = response_data.dig('content', 0, 'text')
      Rails.logger.info "Response content length: #{content&.length || 0}"
      Rails.logger.info "Response content preview: #{content&.first(200)}"
      
      if content
        # JSON 응답 파싱 시도
        begin
          json_match = content.match(/\{.*\}/m)
          if json_match
            parsed_json = JSON.parse(json_match[0])
            Rails.logger.info "Parsed JSON response successfully"
            return parsed_json
          else
            Rails.logger.info "No JSON found in response, creating structured response"
            return {
              "skin_analysis" => content,
              "recommended_treatments" => ["전문의 상담 권장"],
              "estimated_cost" => "상담 후 결정",
              "priority" => "중간",
              "additional_notes" => "전문의와 상담하여 정확한 진단을 받으시기 바랍니다."
            }
          end
        rescue JSON::ParserError => e
          Rails.logger.error "JSON parsing error: #{e.message}"
          return {
            "skin_analysis" => content,
            "recommended_treatments" => ["전문의 상담 권장"],
            "estimated_cost" => "상담 후 결정",
            "priority" => "중간",
            "additional_notes" => "전문의와 상담하여 정확한 진단을 받으시기 바랍니다."
          }
        end
      else
        Rails.logger.error "No content in Claude response"
        raise "Claude API returned empty content"
      end
    else
      Rails.logger.error "Claude API error: #{response.code} - #{response.body}"
      raise "Claude API error: #{response.code}"
    end
  end

  def generate_prompt
    <<~PROMPT
      당신은 10년 경력의 성형외과/피부과 전문의 상담실장입니다. 
      환자의 사진을 보고 전문적이고 솔직한 뷰티 상담을 제공해주세요.
      
      **중요 안내사항:**
      - 이는 교육 목적의 참고용 정보이며 의료 진단이 아닙니다
      - 전문의의 직접 진료를 대체하지 않습니다
      - 개인차가 있으므로 실제 상담 시 다를 수 있습니다
      
      **분석 요청사항:**
      1. 피부 상태를 정확히 관찰하고 분석해주세요
      2. 개선이 필요한 부분을 우선순위별로 제안해주세요
      3. 불필요한 시술은 과감히 제외해주세요
      4. 현실적인 비용 범위를 알려주세요
      5. 병원에서 과도하게 권할 수 있는 시술에 대해 경고해주세요
      
      **응답 형식 (반드시 JSON으로만 응답):**
      {
        "skin_analysis": "피부 상태 상세 분석 (색소침착, 주름, 모공, 탄력, 여드름 등)",
        "recommended_treatments": [
          "1순위 시술 (가장 효과적)",
          "2순위 시술 (필요시)",
          "3순위 시술 (여유 있을 때)"
        ],
        "unnecessary_treatments": [
          "병원에서 권할 수 있지만 불필요한 시술들"
        ],
        "estimated_cost": "현실적인 총 비용 범위 (1순위 기준)",
        "priority": "높음/중간/낮음 (시급성)",
        "cost_saving_tips": "비용 절약 팁",
        "additional_notes": "전문의 상담 시 확인할 점들"
      }
      
      **주의사항:**
      - 과도한 시술 권유는 절대 금지
      - 환자 입장에서 정말 필요한 것만 추천
      - 비용 대비 효과를 고려한 현실적 조언
      - 반드시 위 JSON 형식으로만 응답하고 다른 텍스트는 포함하지 마세요
    PROMPT
  end

  def get_demo_response
    {
      "skin_analysis" => "전반적으로 건강한 피부 상태이나 몇 가지 개선점이 보입니다. 뺨 부위에 경미한 색소침착과 미세한 모공이 관찰되며, 눈가에 초기 잔주름이 시작되고 있습니다. 피부 톤은 균일하나 약간의 칙칙함이 있어 보입니다.",
      "recommended_treatments" => [
        "1순위: 레이저 토닝 (색소침착 개선, 1회 15-20만원, 총 3-5회)",
        "2순위: 보톡스 (눈가 주름 예방, 1회 10-15만원, 6개월마다)",
        "3순위: 스킨부스터 (피부 수분/탄력, 1회 20-30만원, 3회 세트)"
      ],
      "unnecessary_treatments" => [
        "리프팅 시술 (아직 이른 나이, 비용 대비 효과 낮음)",
        "필러 시술 (볼륨 감소 없음, 불필요)",
        "실 리프팅 (현재 상태에서 과도한 시술)"
      ],
      "estimated_cost" => "1순위만 진행 시 60-100만원, 전체 진행 시 120-200만원",
      "priority" => "중간",
      "cost_saving_tips" => "이벤트 기간 이용, 패키지 할인 문의, 여러 병원 견적 비교 필수",
      "additional_notes" => "급하게 결정하지 말고 최소 2-3곳 병원에서 상담받아보세요. 특히 고가의 리프팅이나 필러를 권한다면 신중히 검토하시기 바랍니다."
    }
  end
end
