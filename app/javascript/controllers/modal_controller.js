import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "modal", "emailInput", "successModal", "marketingCheckbox"]

  connect() {
    console.log("Modal controller connected")
    // ESC 키로 모달 닫기
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this.boundCloseOnEscape)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  async open() {
    console.log("Opening modal")
    
    // 버튼 클릭 추적
    await this.trackButtonClick()
    
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
    document.body.style.overflow = "hidden"
    
    // 포커스를 이메일 입력 필드로
    setTimeout(() => {
      this.emailInputTarget.focus()
    }, 100)
  }

  close() {
    console.log("Closing modal")
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
    document.body.style.overflow = ""
    
    // 폼 리셋
    this.resetForm()
  }

  closeSuccess() {
    this.successModalTarget.classList.add("hidden")
    this.successModalTarget.classList.remove("flex")
    document.body.style.overflow = ""
    this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  async submitEmail(event) {
    event.preventDefault()
    console.log("Submitting email")
    
    const email = this.emailInputTarget.value
    const marketingConsent = this.hasMarketingCheckboxTarget ? 
      this.marketingCheckboxTarget.checked : false
    
    if (!email) {
      alert("이메일을 입력해주세요.")
      return
    }

    try {
      const response = await fetch('/pre_orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({
          pre_order: {
            email: email,
            marketing_consent: marketingConsent
          }
        })
      })

      const data = await response.json()
      
      if (data.success) {
        // 성공 모달 표시
        this.overlayTarget.classList.add("hidden")
        this.overlayTarget.classList.remove("flex")
        this.successModalTarget.classList.remove("hidden")
        this.successModalTarget.classList.add("flex")
      } else {
        alert(data.message || "오류가 발생했습니다.")
      }
    } catch (error) {
      console.error("Error:", error)
      alert("네트워크 오류가 발생했습니다.")
    }
  }

  async trackButtonClick() {
    try {
      await fetch('/button_clicks', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })
    } catch (error) {
      console.log("Button click tracking failed:", error)
      // 추적 실패해도 모달은 정상 동작
    }
  }

  resetForm() {
    this.emailInputTarget.value = ""
    if (this.hasMarketingCheckboxTarget) {
      this.marketingCheckboxTarget.checked = false
    }
  }
} 