import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    event.preventDefault()
    
    // 폼 데이터 수집
    const formData = new FormData(event.target)
    const skinType = formData.get('skinType') || event.target.querySelector('select').value
    const concerns = formData.get('concerns') || event.target.querySelector('textarea').value
    const budget = formData.get('budget') || event.target.querySelectorAll('select')[1].value
    
    // 로딩 상태 표시
    const submitButton = event.target.querySelector('button[type="submit"]')
    const originalText = submitButton.textContent
    submitButton.textContent = "AI 분석 중..."
    submitButton.disabled = true
    
    // 간단한 AI 분석 시뮬레이션
    setTimeout(() => {
      this.showResults(skinType, concerns, budget)
      submitButton.textContent = originalText
      submitButton.disabled = false
    }, 2000)
  }
  
  showResults(skinType, concerns, budget) {
    // 결과 모달 내용 생성
    const recommendations = this.generateRecommendations(skinType, concerns, budget)
    
    // 모달 내용 교체
    const modal = document.getElementById("consultationModal")
    const modalContent = modal.querySelector('.bg-white')
    
    modalContent.innerHTML = `
      <div class="flex justify-between items-center mb-6">
        <h3 class="text-2xl font-bold text-gray-800">AI 분석 결과</h3>
        <button class="text-gray-500 hover:text-gray-700" data-action="click->modal#close">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
      
      <div class="space-y-4">
        <div class="bg-gradient-to-r from-pink-50 to-purple-50 p-4 rounded-lg">
          <h4 class="font-semibold text-gray-800 mb-2">당신의 피부 분석</h4>
          <p class="text-gray-600">${skinType} 피부로 분석되었습니다.</p>
        </div>
        
        <div class="bg-blue-50 p-4 rounded-lg">
          <h4 class="font-semibold text-gray-800 mb-2">추천 제품</h4>
          <ul class="text-gray-600 space-y-1">
            ${recommendations.map(item => `<li>• ${item}</li>`).join('')}
          </ul>
        </div>
        
        <div class="bg-green-50 p-4 rounded-lg">
          <h4 class="font-semibold text-gray-800 mb-2">뷰티 루틴</h4>
          <p class="text-gray-600">아침: 클렌징 → 토너 → 세럼 → 모이스처라이저 → 선크림</p>
          <p class="text-gray-600">저녁: 클렌징 → 토너 → 세럼 → 모이스처라이저</p>
        </div>
        
        <button class="w-full bg-gradient-to-r from-pink-500 to-purple-600 text-white py-3 rounded-lg font-semibold hover:from-pink-600 hover:to-purple-700 transition duration-300"
                data-action="click->modal#close">
          결과 저장하기
        </button>
      </div>
    `
  }
  
  generateRecommendations(skinType, concerns, budget) {
    const recommendations = []
    
    if (skinType === '건성') {
      recommendations.push('히알루론산 세럼')
      recommendations.push('크림 타입 모이스처라이저')
    } else if (skinType === '지성') {
      recommendations.push('나이아신아마이드 세럼')
      recommendations.push('젤 타입 모이스처라이저')
    } else if (skinType === '복합성') {
      recommendations.push('균형 잡힌 토너')
      recommendations.push('가벼운 에멀전')
    } else if (skinType === '민감성') {
      recommendations.push('센텔라 진정 세럼')
      recommendations.push('무향료 모이스처라이저')
    }
    
    if (concerns.includes('여드름')) {
      recommendations.push('살리실산 클렌저')
    }
    if (concerns.includes('주름')) {
      recommendations.push('레티놀 크림')
    }
    if (concerns.includes('색소침착')) {
      recommendations.push('비타민C 세럼')
    }
    
    return recommendations
  }
} 