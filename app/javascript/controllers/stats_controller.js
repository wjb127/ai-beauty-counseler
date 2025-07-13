import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]

  connect() {
    this.renderStats()
  }

  renderStats() {
    const stats = [
      {
        title: "총 사용자",
        value: "1,234",
        color: "from-blue-500 to-indigo-600",
        icon: "👥"
      },
      {
        title: "완료된 할일",
        value: "5,678",
        color: "from-green-500 to-emerald-600", 
        icon: "✅"
      },
      {
        title: "활성 사용자",
        value: "890",
        color: "from-purple-500 to-pink-600",
        icon: "🔥"
      }
    ]

    const html = stats.map(stat => `
      <div class="bg-white rounded-xl p-6 shadow-lg border border-gray-100">
        <div class="flex items-center justify-between mb-4">
          <div class="text-2xl">${stat.icon}</div>
          <div class="text-sm text-gray-500">${stat.title}</div>
        </div>
        <div class="text-3xl font-bold bg-gradient-to-r ${stat.color} bg-clip-text text-transparent">
          ${stat.value}
        </div>
      </div>
    `).join('')

    this.displayTarget.innerHTML = html
  }
} 