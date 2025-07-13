class AnalysisController < ApplicationController
  require 'openai'
  require 'base64'

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
    if request.post?
      # 세션 기반 사용 제한 체크 (1인당 3회)
      session[:analysis_count] ||= 0
      
      if session[:analysis_count] >= 3
        render json: {
          success: false,
          error: "일일 분석 한도(3회)를 초과했습니다. 내일 다시 이용해주세요.",
          limit_exceeded: true
        }
        return
      end

      begin
        image_data = params[:image]
        
        # base64에서 실제 이미지 데이터 추출
        if image_data.include?('base64,')
          image_data = image_data.split('base64,')[1]
        end

        # OpenAI 클라이언트 초기화
        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'] || 'demo_key')

        # GPT-4 Vision API 호출 (데모용 응답)
        analysis_result = if ENV['OPENAI_API_KEY'].present?
          call_openai_api(client, image_data)
        else
          generate_demo_response
        end

        # 분석 성공 시 카운트 증가
        session[:analysis_count] = session[:analysis_count] + 1
        remaining_count = 3 - session[:analysis_count]

        render json: {
          success: true,
          analysis: analysis_result,
          remaining_count: remaining_count,
          total_limit: 3
        }

      rescue => e
        Rails.logger.error "Analysis error: #{e.message}"
        render json: {
          success: false,
          error: "분석 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        }
      end
    else
      render json: { success: false, error: "잘못된 요청입니다." }
    end
  end

  private

  def call_openai_api(client, image_data)
    prompt = build_analysis_prompt

    response = client.chat(
      parameters: {
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
    )

    parse_ai_response(response.dig("choices", 0, "message", "content"))
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
