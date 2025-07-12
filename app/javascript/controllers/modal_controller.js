import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.modal = document.getElementById("consultationModal")
  }

  open() {
    this.modal.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.modal.classList.add("hidden")
    document.body.style.overflow = "auto"
  }

  // 모달 배경 클릭 시 닫기
  closeOnBackdrop(event) {
    if (event.target === this.modal) {
      this.close()
    }
  }

  // ESC 키로 모달 닫기
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
} 