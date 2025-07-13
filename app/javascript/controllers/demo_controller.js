import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "uploadArea", "fileInput", "uploadPrompt", "imagePreview", "previewImage",
    "analyzeButton", "analyzeButtonText", "resultArea", "waitingState", 
    "loadingState", "resultContent"
  ]

  connect() {
    // 업로드 영역 클릭 시 파일 선택 창 열기
    this.uploadAreaTarget.addEventListener('click', () => {
      this.fileInputTarget.click()
    })
    
    // 페이지 로드 시 남은 분석 횟수 확인
    this.checkRemainingCount()
  }

  async checkRemainingCount() {
    try {
      const response = await fetch('/check_analysis_count', {
        method: 'GET',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      const result = await response.json()
      if (result.remaining_count !== undefined) {
        this.updateCountDisplay(result.remaining_count, result.total_limit)
      }
    } catch (error) {
      console.log('카운트 확인 중 오류:', error)
    }
  }

  handleFileSelect(event) {
    const file = event.target.files[0]
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewImageTarget.src = e.target.result
        this.uploadPromptTarget.classList.add('hidden')
        this.imagePreviewTarget.classList.remove('hidden')
        this.analyzeButtonTarget.disabled = false
        this.analyzeButtonTarget.classList.remove('disabled:from-gray-400', 'disabled:to-gray-500')
        this.analyzeButtonTarget.classList.add('from-blue-600', 'to-blue-700', 'hover:from-blue-700', 'hover:to-blue-800')
      }
      reader.readAsDataURL(file)
    }
  }

  async analyzeImage() {
    console.log('=== AI 분석 시작 ===')
    
    // 로딩 상태로 변경
    this.waitingStateTarget.classList.add('hidden')
    this.loadingStateTarget.classList.remove('hidden')
    this.analyzeButtonTarget.disabled = true
    this.analyzeButtonTextTarget.textContent = '분석 중...'

    try {
      // 이미지를 base64로 변환
      const imageData = this.previewImageTarget.src
      console.log('Image data length:', imageData ? imageData.length : 0)
      console.log('Image data preview:', imageData ? imageData.substring(0, 100) : 'No data')

      if (!imageData) {
        throw new Error('이미지 데이터가 없습니다.')
      }

      console.log('Sending request to /analyze_image...')

      // API 호출
      const response = await fetch('/analyze_image', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          image: imageData
        })
      })

      console.log('Response status:', response.status)
      console.log('Response headers:', Object.fromEntries(response.headers.entries()))

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const result = await response.json()
      console.log('Response result:', result)

      if (result.success) {
        console.log('Analysis successful')
        this.displayResult(result.analysis)
        // 남은 횟수 업데이트
        if (result.remaining_count !== undefined) {
          this.updateCountDisplay(result.remaining_count, result.total_limit)
        }
      } else {
        console.log('Analysis failed:', result.error)
        if (result.limit_exceeded) {
          this.displayLimitExceeded(result.error)
        } else {
          this.displayError(result.error || '분석 중 오류가 발생했습니다.')
        }
      }
    } catch (error) {
      console.error('=== Analysis Error ===')
      console.error('Error type:', error.constructor.name)
      console.error('Error message:', error.message)
      console.error('Error stack:', error.stack)
      
      let errorMessage = '네트워크 오류가 발생했습니다.'
      
      if (error.message.includes('HTTP')) {
        errorMessage = `서버 오류: ${error.message}`
      } else if (error.message.includes('Failed to fetch')) {
        errorMessage = '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.'
      } else if (error.message) {
        errorMessage = error.message
      }
      
      this.displayError(errorMessage)
    }

    // 버튼 상태 복원
    this.analyzeButtonTarget.disabled = false
    this.analyzeButtonTextTarget.textContent = '다시 분석하기'
    
    console.log('=== AI 분석 종료 ===')
  }

  displayResult(analysis) {
    this.loadingStateTarget.classList.add('hidden')
    this.resultContentTarget.classList.remove('hidden')
    
    this.resultContentTarget.innerHTML = `
      <div class="space-y-6">
        <!-- 분석 요약 -->
        <div class="bg-blue-50 rounded-lg p-4 border-l-4 border-blue-500">
          <h4 class="font-semibold text-blue-800 mb-2">📋 AI 분석 요약</h4>
          <p class="text-blue-700 text-sm">${analysis.summary || '전반적인 피부 상태를 분석했습니다.'}</p>
        </div>

        <!-- 추천 시술 -->
        <div class="space-y-3">
          <h4 class="font-semibold text-gray-800">💡 추천 시술</h4>
          ${this.renderRecommendations(analysis.recommendations)}
        </div>

        <!-- 주의사항 -->
        <div class="space-y-3">
          <h4 class="font-semibold text-gray-800">⚠️ 주의사항</h4>
          ${this.renderWarnings(analysis.warnings)}
        </div>

        <!-- 예상 비용 -->
        ${analysis.cost_estimate ? `
          <div class="bg-green-50 rounded-lg p-4">
            <h4 class="font-semibold text-green-800 mb-2">💰 예상 비용 범위</h4>
            <p class="text-green-700 text-sm">${analysis.cost_estimate}</p>
          </div>
        ` : ''}

        <!-- 다음 단계 -->
        <div class="bg-gray-50 rounded-lg p-4">
          <h4 class="font-semibold text-gray-800 mb-2">🎯 다음 단계</h4>
          <ul class="text-sm text-gray-600 space-y-1">
            <li>• 이 분석 결과를 출력하여 병원 상담 시 참고자료로 활용</li>
            <li>• 여러 병원에서 견적을 받아 비교 검토</li>
            <li>• 급하지 않다면 충분한 시간을 두고 신중하게 결정</li>
            <li>• 의사의 설명과 AI 분석을 종합하여 최종 판단</li>
          </ul>
        </div>
      </div>
    `
  }

  renderRecommendations(recommendations) {
    if (!recommendations || recommendations.length === 0) {
      return '<p class="text-gray-500 text-sm">현재 상태로는 특별한 시술이 필요하지 않아 보입니다.</p>'
    }

    return recommendations.map(rec => `
      <div class="bg-white border rounded-lg p-3">
        <div class="flex items-start space-x-3">
          <div class="w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
            <span class="text-blue-600 text-xs font-bold">${rec.priority || '★'}</span>
          </div>
          <div class="flex-1">
            <h5 class="font-medium text-gray-800">${rec.treatment}</h5>
            <p class="text-sm text-gray-600 mt-1">${rec.reason}</p>
            ${rec.urgency ? `<span class="inline-block mt-2 px-2 py-1 bg-${rec.urgency === 'high' ? 'red' : rec.urgency === 'medium' ? 'yellow' : 'green'}-100 text-${rec.urgency === 'high' ? 'red' : rec.urgency === 'medium' ? 'yellow' : 'green'}-800 text-xs rounded">${rec.urgency === 'high' ? '높은 우선순위' : rec.urgency === 'medium' ? '보통 우선순위' : '낮은 우선순위'}</span>` : ''}
          </div>
        </div>
      </div>
    `).join('')
  }

  renderWarnings(warnings) {
    if (!warnings || warnings.length === 0) {
      return '<p class="text-gray-500 text-sm">특별한 주의사항은 없습니다.</p>'
    }

    return warnings.map(warning => `
      <div class="bg-yellow-50 border-l-4 border-yellow-400 p-3">
        <p class="text-yellow-800 text-sm">${warning}</p>
      </div>
    `).join('')
  }

  displayError(message) {
    this.loadingStateTarget.classList.add('hidden')
    this.resultContentTarget.classList.remove('hidden')
    
    this.resultContentTarget.innerHTML = `
      <div class="text-center py-8">
        <div class="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
        </div>
        <h4 class="text-lg font-semibold text-gray-800 mb-2">분석 실패</h4>
        <p class="text-gray-600 mb-4">${message}</p>
        <button onclick="location.reload()" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm">
          다시 시도하기
        </button>
      </div>
    `
  }

  updateCountDisplay(remaining, total) {
    const countInfo = document.getElementById('analysis-count-info')
    if (countInfo) {
      countInfo.innerHTML = `
        <div class="text-center mb-4">
          <span class="inline-block px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
            남은 분석 횟수: ${remaining}/${total}
          </span>
        </div>
      `
    }
  }

  displayLimitExceeded(message) {
    this.loadingStateTarget.classList.add('hidden')
    this.resultContentTarget.classList.remove('hidden')
    
    this.resultContentTarget.innerHTML = `
      <div class="text-center py-8">
        <div class="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
        </div>
        <h4 class="text-lg font-semibold text-gray-800 mb-2">분석 횟수 초과</h4>
        <p class="text-gray-600 mb-4">${message}</p>
        <div class="bg-blue-50 rounded-lg p-4 text-sm text-blue-800">
          <p class="font-medium mb-2">💡 더 많은 분석을 원하시나요?</p>
          <p>프리미엄 서비스 출시 예정! 사전 예약하시면 특별 할인 혜택을 드립니다.</p>
        </div>
      </div>
    `
  }
} 