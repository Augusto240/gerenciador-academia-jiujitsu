// app.js - JavaScript compartilhado do sistema JPM Team

// Atualizar opções de graduação baseado na modalidade selecionada
function atualizarGraduacoes() {
  var modalidade = document.getElementById('modalidade').value;
  var corFaixaSelect = document.getElementById('cor_faixa');
  
  if (!corFaixaSelect) return;
  
  // Limpar opções atuais
  corFaixaSelect.innerHTML = '';
  
  var faixas = [];
  
  if (modalidade === 'Jiu Jitsu') {
    faixas = [
      { value: 'Branca', text: 'Branca' },
      { value: 'Cinza', text: 'Cinza' },
      { value: 'Amarela', text: 'Amarela' },
      { value: 'Laranja', text: 'Laranja' },
      { value: 'Verde', text: 'Verde' },
      { value: 'Azul', text: 'Azul' },
      { value: 'Roxa', text: 'Roxa' },
      { value: 'Marrom', text: 'Marrom' },
      { value: 'Preta', text: 'Preta' }
    ];
  } else if (modalidade === 'Muay Thai') {
    faixas = [
      { value: 'Branca', text: 'Branca' },
      { value: 'Amarela', text: 'Amarela' },
      { value: 'Verde', text: 'Verde' },
      { value: 'Azul', text: 'Azul' },
      { value: 'Roxa', text: 'Roxa' },
      { value: 'Marrom', text: 'Marrom' },
      { value: 'Preta', text: 'Preta' }
    ];
  }
  
  faixas.forEach(function(faixa) {
    var option = document.createElement('option');
    option.value = faixa.value;
    option.textContent = faixa.text;
    corFaixaSelect.appendChild(option);
  });
}

// Atualizar turmas baseado na modalidade
function atualizarTurmas() {
  var modalidade = document.getElementById('modalidade');
  var turmaSelect = document.getElementById('turma');
  
  if (!modalidade || !turmaSelect) return;
  
  // Limpar opções atuais
  turmaSelect.innerHTML = '';
  
  var turmas = [];
  
  if (modalidade.value === 'Jiu Jitsu') {
    turmas = [
      { value: '', text: 'Selecione uma turma' },
      { value: 'Kids', text: 'Kids (4-7 anos)' },
      { value: 'Infantil', text: 'Infantil (8-12 anos)' },
      { value: 'Juvenil', text: 'Juvenil (13-17 anos)' },
      { value: 'Adultos', text: 'Adultos (18+)' }
    ];
  } else if (modalidade.value === 'Muay Thai') {
    turmas = [
      { value: 'Muay Thai', text: 'Muay Thai' }
    ];
  }
  
  turmas.forEach(function(turma) {
    var option = document.createElement('option');
    option.value = turma.value;
    option.textContent = turma.text;
    turmaSelect.appendChild(option);
  });
}

// Modal de confirmação customizado
function mostrarModalConfirmacao(mensagem, callback) {
  var modal = document.getElementById('confirmModal');
  var mensagemEl = document.getElementById('confirmMessage');
  var btnConfirm = document.getElementById('btnConfirm');
  var btnCancel = document.getElementById('btnCancel');
  
  if (!modal || !mensagemEl) return;
  
  mensagemEl.textContent = mensagem;
  modal.style.display = 'flex';
  
  btnConfirm.onclick = function() {
    modal.style.display = 'none';
    if (callback) callback();
  };
  
  btnCancel.onclick = function() {
    modal.style.display = 'none';
  };
}

// Fechar modal ao clicar fora
document.addEventListener('DOMContentLoaded', function() {
  var modal = document.getElementById('confirmModal');
  if (modal) {
    modal.addEventListener('click', function(e) {
      if (e.target === modal) {
        modal.style.display = 'none';
      }
    });
  }
  
  // Interceptar formulários com data-confirm
  document.querySelectorAll('form[data-confirm]').forEach(function(form) {
    form.addEventListener('submit', function(e) {
      e.preventDefault();
      var mensagem = form.getAttribute('data-confirm');
      mostrarModalConfirmacao(mensagem, function() {
        form.submit();
      });
    });
  });
  
  // Interceptar links com data-confirm
  document.querySelectorAll('a[data-confirm]').forEach(function(link) {
    link.addEventListener('click', function(e) {
      e.preventDefault();
      var mensagem = link.getAttribute('data-confirm');
      mostrarModalConfirmacao(mensagem, function() {
        window.location.href = link.href;
      });
    });
  });
  
  // Loading feedback em formulários
  document.querySelectorAll('form').forEach(function(form) {
    form.addEventListener('submit', function() {
      var submitBtn = form.querySelector('button[type="submit"]');
      if (submitBtn && !form.hasAttribute('data-confirm')) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = 'Aguarde...';
      }
    });
  });
});

// Função para excluir aula via DELETE
function excluirAula(aulaId, csrfToken) {
  mostrarModalConfirmacao('Tem certeza que deseja excluir esta aula? Esta ação não pode ser desfeita.', function() {
    // Criar form para enviar DELETE
    var form = document.createElement('form');
    form.method = 'POST';
    form.action = '/aulas/' + aulaId;
    
    // Adicionar _method para DELETE
    var methodInput = document.createElement('input');
    methodInput.type = 'hidden';
    methodInput.name = '_method';
    methodInput.value = 'DELETE';
    form.appendChild(methodInput);
    
    // Adicionar CSRF token
    var csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = '_csrf';
    csrfInput.value = csrfToken;
    form.appendChild(csrfInput);
    
    document.body.appendChild(form);
    form.submit();
  });
}
