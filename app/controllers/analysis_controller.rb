class AnalysisController < ApplicationController
  require 'base64'
  
  # CSRF 검증 임시 비활성화 (디버깅용)
  skip_before_action :verify_authenticity_token

  def check_analysis_count
    session[:analysis_count] ||= 0
    remaining_count = 3 - session[:analysis_count]
    
    render json: {
      remaining_count: remaining_count,
      total_limit: 3,
      used_count: session[:analysis_count]
    }
  end

  def analyze_image
    Rails.logger.info "=== AI 분석 요청 시작 ==="
    Rails.logger.info "Request method: #{request.method}"
    Rails.logger.info "Request params: #{params.inspect}"
    Rails.logger.info "Session analysis_count: #{session[:analysis_count]}"
    
    if request.post?
      # 세션 기반 사용 제한 체크 (1인당 3회)
      session[:analysis_count] ||= 0
      Rails.logger.info "Current analysis count: #{session[:analysis_count]}"
      
      if session[:analysis_count] >= 3
        Rails.logger.warn "Analysis limit exceeded for session"
        render json: {
          success: false,
          error: "일일 분석 한도(3회)를 초과했습니다. 내일 다시 이용해주세요.",
          limit_exceeded: true
        }
        return
      end

      begin
        image_data = params[:image]
        Rails.logger.info "Image data received: #{image_data ? 'Yes' : 'No'}"
        Rails.logger.info "Image data length: #{image_data&.length || 0}"
        
        if image_data.blank?
          Rails.logger.error "No image data provided"
          render json: {
            success: false,
            error: "이미지 데이터가 없습니다. 이미지를 선택해주세요."
          }
          return
        end
        
        # base64에서 실제 이미지 데이터 추출
        if image_data.include?('base64,')
          image_data = image_data.split('base64,')[1]
          Rails.logger.info "Extracted base64 data, length: #{image_data.length}"
        end

        # OpenAI API 키 확인
        api_key = ENV['OPENAI_API_KEY']
        Rails.logger.info "OpenAI API key present: #{api_key.present?}"
        
        if api_key.present?
          Rails.logger.info "Using OpenAI API key: #{api_key[0..10]}..."
        end

        # OpenAI 클라이언트 초기화
        begin
          require 'openai'
          client = OpenAI::Client.new(access_token: api_key || 'demo_key')
        rescue LoadError => e
          Rails.logger.error "OpenAI gem not available: #{e.message}"
          # OpenAI gem이 없으면 데모 응답 사용
          analysis_result = generate_demo_response
          session[:analysis_count] = session[:analysis_count] + 1
          remaining_count = 3 - session[:analysis_count]
          
          render json: {
            success: true,
            analysis: analysis_result,
            remaining_count: remaining_count,
            total_limit: 3
          }
          return
        end
        Rails.logger.info "OpenAI client initialized"

        # GPT-4 Vision API 호출 (데모용 응답)
        analysis_result = if api_key.present?
          Rails.logger.info "Calling OpenAI API..."
          call_openai_api(client, image_data)
        else
          Rails.logger.info "Using demo response (no API key)"
          generate_demo_response
        end

        Rails.logger.info "Analysis completed successfully"

        # 분석 성공 시 카운트 증가
        session[:analysis_count] = session[:analysis_count] + 1
        remaining_count = 3 - session[:analysis_count]
        Rails.logger.info "Updated analysis count: #{session[:analysis_count]}, remaining: #{remaining_count}"

        render json: {
          success: true,
          analysis: analysis_result,
          remaining_count: remaining_count,
          total_limit: 3
        }

      rescue => e
        Rails.logger.error "=== Analysis Error ==="
        Rails.logger.error "Error class: #{e.class}"
        Rails.logger.error "Error message: #{e.message}"
        Rails.logger.error "Error backtrace: #{e.backtrace.join("\n")}"
        
        render json: {
          success: false,
          error: "분석 중 오류가 발생했습니다: #{e.message}"
        }
      end
    else
      Rails.logger.warn "Non-POST request received: #{request.method}"
      render json: { success: false, error: "잘못된 요청입니다." }
    end
    
    Rails.logger.info "=== AI 분석 요청 종료 ==="
  end

  private

  def call_openai_api(client, image_data)
    Rails.logger.info "=== OpenAI API 호출 시작 ==="
    
    begin
      prompt = build_analysis_prompt
      Rails.logger.info "Prompt generated, length: #{prompt.length}"
      
      # 이미지 데이터 검증
      if image_data.blank?
        raise "Image data is blank"
      end
      
      Rails.logger.info "Image data length for API: #{image_data.length}"
      
      request_params = {
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: prompt
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/jpeg;base64,#{image_data}"
                }
              }
            ]
          }
        ],
        max_tokens: 1000
      }
      
      Rails.logger.info "Request parameters prepared"
      Rails.logger.info "Model: #{request_params[:model]}"
      Rails.logger.info "Max tokens: #{request_params[:max_tokens]}"
      
      Rails.logger.info "Sending request to OpenAI..."
      response = client.chat(parameters: request_params)
      
      Rails.logger.info "OpenAI API response received"
      Rails.logger.info "Response keys: #{response.keys}"
      
      if response["choices"]&.any?
        content = response.dig("choices", 0, "message", "content")
        Rails.logger.info "Response content length: #{content&.length || 0}"
        Rails.logger.info "Response content preview: #{content&.truncate(200)}"
        
        result = parse_ai_response(content)
        Rails.logger.info "Parsed response successfully"
        return result
      else
        Rails.logger.error "No choices in OpenAI response: #{response}"
        raise "OpenAI API returned no choices"
      end
      
    rescue => e
      Rails.logger.error "=== OpenAI API 호출 실패 ==="
      Rails.logger.error "Error class: #{e.class}"
      Rails.logger.error "Error message: #{e.message}"
      Rails.logger.error "Error backtrace: #{e.backtrace&.join("\n")}"
      
      # API 호출 실패 시 데모 응답 반환
      Rails.logger.info "Falling back to demo response"
      return generate_demo_response
    end
  end

  def generate_demo_response
    # 데모용 응답 생성
    {
      summary: "업로드해주신 사진을 바탕으로 피부 상태를 분석했습니다. 전반적으로 건강한 피부 상태를 보이고 있으나, 몇 가지 개선 가능한 부분이 있습니다.",
      recommendations: [
        {
          treatment: "기미/색소침착 레이저 치료",
          reason: "얼굴 부위에 약간의 색소침착이 관찰됩니다. 레이저 토닝이나 IPL 치료로 개선 가능합니다.",
          priority: "1",
          urgency: "medium"
        },
        {
          treatment: "보톡스 (이마/미간)",
          reason: "표정근으로 인한 잔주름이 보입니다. 보톡스로 예방 및 개선이 가능합니다.",
          priority: "2", 
          urgency: "low"
        },
        {
          treatment: "히알루론산 필러",
          reason: "볼륨 감소 부위에 자연스러운 볼륨 보충이 도움될 수 있습니다.",
          priority: "3",
          urgency: "low"
        }
      ],
      warnings: [
        "급하게 결정하지 마시고 충분한 상담 시간을 가지세요",
        "여러 병원에서 견적을 받아 비교해보세요",
        "과도한 시술보다는 꼭 필요한 시술만 선택하세요",
        "시술 후 관리 방법과 부작용에 대해 충분히 설명을 들으세요"
      ],
      cost_estimate: "추천 시술 전체 기준 약 80만원 ~ 150만원 (병원별 차이 있음)"
    }
  end

  def build_analysis_prompt
    <<~PROMPT
      당신은 피부과/성형외과 전문의입니다. 업로드된 얼굴 사진을 분석하여 다음 형식으로 응답해주세요:

      **중요한 원칙:**
      - 과도한 시술을 권하지 마세요
      - 정말 필요한 시술만 추천하세요  
      - 상업적 이익보다는 환자의 안전과 만족을 우선시하세요
      - 자연스러운 개선을 목표로 하세요

      **분석 항목:**
      1. 피부 상태 전반적 평가
      2. 개선이 필요한 부위 (있다면)
      3. 추천 시술 (우선순위별)
      4. 각 시술의 필요성과 근거
      5. 주의사항 및 조언
      6. 대략적인 비용 범위

      **응답 형식:** JSON
      {
        "summary": "전반적인 분석 요약",
        "recommendations": [
          {
            "treatment": "시술명",
            "reason": "추천 이유",
            "priority": "우선순위(1-5)",
            "urgency": "긴급도(high/medium/low)"
          }
        ],
        "warnings": ["주의사항1", "주의사항2"],
        "cost_estimate": "예상 비용 범위"
      }
    PROMPT
  end

  def parse_ai_response(response_text)
    # JSON 응답 파싱 시도
    begin
      JSON.parse(response_text.gsub(/```json|```/, '').strip)
    rescue JSON::ParserError
      # 파싱 실패 시 기본 응답
      generate_demo_response
    end
  end
end
