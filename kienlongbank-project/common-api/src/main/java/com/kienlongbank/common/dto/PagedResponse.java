package com.kienlongbank.common.dto;

import java.io.Serializable;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Paginated response wrapper for list data with pagination information
 * 
 * @param <T> the type of data being returned in the list
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class PagedResponse<T> implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private List<T> content;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;
    private boolean first;
    private boolean last;
    private boolean empty;
    
    // Default constructor
    public PagedResponse() {}
    
    // Constructor with all fields
    public PagedResponse(List<T> content, int page, int size, long totalElements) {
        this.content = content;
        this.page = page;
        this.size = size;
        this.totalElements = totalElements;
        this.totalPages = (int) Math.ceil((double) totalElements / size);
        this.first = page == 0;
        this.last = page >= totalPages - 1;
        this.empty = content == null || content.isEmpty();
    }
    
    // Static factory method
    public static <T> PagedResponse<T> of(List<T> content, int page, int size, long totalElements) {
        return new PagedResponse<>(content, page, size, totalElements);
    }
    
    // Getters and Setters
    public List<T> getContent() {
        return content;
    }
    
    public void setContent(List<T> content) {
        this.content = content;
        this.empty = content == null || content.isEmpty();
    }
    
    public int getPage() {
        return page;
    }
    
    public void setPage(int page) {
        this.page = page;
        this.first = page == 0;
    }
    
    public int getSize() {
        return size;
    }
    
    public void setSize(int size) {
        this.size = size;
        this.totalPages = size > 0 ? (int) Math.ceil((double) totalElements / size) : 0;
    }
    
    public long getTotalElements() {
        return totalElements;
    }
    
    public void setTotalElements(long totalElements) {
        this.totalElements = totalElements;
        this.totalPages = size > 0 ? (int) Math.ceil((double) totalElements / size) : 0;
        this.last = page >= totalPages - 1;
    }
    
    public int getTotalPages() {
        return totalPages;
    }
    
    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
        this.last = page >= totalPages - 1;
    }
    
    public boolean isFirst() {
        return first;
    }
    
    public void setFirst(boolean first) {
        this.first = first;
    }
    
    public boolean isLast() {
        return last;
    }
    
    public void setLast(boolean last) {
        this.last = last;
    }
    
    public boolean isEmpty() {
        return empty;
    }
    
    public void setEmpty(boolean empty) {
        this.empty = empty;
    }
    
    public boolean hasContent() {
        return !empty;
    }
    
    public boolean hasNext() {
        return !last;
    }
    
    public boolean hasPrevious() {
        return !first;
    }
    
    @Override
    public String toString() {
        return "PagedResponse{" +
                "content=" + content +
                ", page=" + page +
                ", size=" + size +
                ", totalElements=" + totalElements +
                ", totalPages=" + totalPages +
                ", first=" + first +
                ", last=" + last +
                ", empty=" + empty +
                '}';
    }
}
